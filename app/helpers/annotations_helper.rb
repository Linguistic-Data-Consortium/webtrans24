module AnnotationsHelper

=begin

The annotation_journals table looks like this:

  integer "id"
  integer "user_id"
  integer "task_id"
  integer "kit_id"
  integer "tree_id"
  json "json"

The json field contains a json object sent by the client, while the other fields
are metadata that are known at the time of the request.  The division is somewhat
arbitrary, in that metadata could be within the json as well, but the idea is
that the json object contains a bundle of annotations sent at one time.  The main
purpose of this table is to save what was sent without processing.  The journals are
unpacked into the annotations table, making the journals mostly redundant.  They can
be used to recreate rows in the annotations table, but since they're redundant they could
also be taken offline to reclaim database space.

The annotations table looks like this (currently called xnnotations)

  integer "id"
  integer "transaction_id"
  integer "parent_id"
  integer "user_id"
  integer "task_id"
  integer "kit_id"
  integer "tree_id"
  integer "node_value_id"
  integer "iid"
  string "message"

These rows represent the logical sequence of annotations made by the client.  They're
created from the annotation_journals as a convenience, but a different API might
create them directly.  The following trigger creates annotations from annotation_journals.

=end

  def create_annotations_trigger
    # "
    # CREATE OR REPLACE TRIGGER create_annotations_trigger
    "
    CREATE TRIGGER create_annotations_trigger
    AFTER INSERT ON xnnotation_journals
    FOR EACH ROW EXECUTE FUNCTION create_annotations_trigger_function();
    "
  end

# The trigger function wraps another function so that the same logic can be done without
# relying on the trigger:

  def create_annotations_trigger_function
    "
    CREATE OR REPLACE FUNCTION create_annotations_trigger_function() RETURNS TRIGGER AS $$
    BEGIN
      PERFORM create_annotations(NEW);
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

# The following database function creates rows in annotations from a single row in annotation_journals.
# It could be used outside the trigger, although you'd have to be sure there weren't conflicting
# rows in annotations already.  So e.g.:
#   DELETE FROM annotations WHERE transaction_id = 1;
#   SELECT create_annotations(annotation_journals) FROM annotation_journals WHERE id = 1;

  def create_annotations
    # The main purpose of this function is to unpack a single json object into a sequence
    # of separate logical annotations, inserted into the annotations table and indirectly
    # the node_values table.  While annotations.id is enough to determine that sequence,
    # this function also fills in annotations.parent_id to form a linked list.
    # Note that some insertion values don't change across loop iterations.
    "
    CREATE OR REPLACE FUNCTION create_annotations(journal xnnotation_journals) RETURNS int AS $$
    DECLARE
      nw timestamp := now();
      m json;
      parent_id int;
    BEGIN
      -- parent_id starts from the last annotation id for this tree
      SELECT id INTO parent_id FROM xnnotations WHERE tree_id = journal.tree_id ORDER BY id DESC LIMIT 1;
      FOR m IN SELECT * FROM json_array_elements( journal.json->'messages' )
      LOOP
        INSERT INTO xnnotations (
          transaction_id,
          parent_id,
          user_id,
          task_id,
          kit_id,
          tree_id,
          message,
          iid,
          node_value_id,
          created_at,
          updated_at
        )
        VALUES (
          journal.id,
          parent_id,                     -- the id of the previous annotation
          journal.user_id,
          journal.task_id,
          journal.kit_id,
          journal.tree_id,
          m->>'message',                 -- the specific annotation message/type
          (m->>'node')::int,             -- the iid (internal id of the annotation)
          create_node_value(m->'value'), -- return value points to the annotation content
          nw,                            
          nw                             
        )
        RETURNING id INTO parent_id;     -- update parent_id
      END LOOP;
      RETURN journal.id;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

=begin

The annotations table is an immutable list of the operations that have taken place,
more like a log than a structure.  Instead, the nodes table is used to represent
the structure of currently existing annotations.

The nodes table looks like this: (currently called xodes)

  integer "id"
  string "name"
  integer "user_id"
  integer "task_id"
  integer "parent_id"
  integer "parent_iid"
  integer "tree_id"
  integer "node_value_id"
  integer "index"
  integer "iid"
  integer "level"

The insertion of a single row in the annotations table performs one or more operations
on the nodes table via the following trigger.

=end

  def apply_annotation_trigger
    # "
    # CREATE OR REPLACE TRIGGER apply_annotation_trigger
    "
    CREATE TRIGGER apply_annotation_trigger
    AFTER INSERT ON xnnotations
    FOR EACH ROW EXECUTE FUNCTION apply_annotation_trigger_function();
    "
  end

# The trigger function wraps another function so that the same logic can be done without
# relying on the trigger:

  def apply_annotation_trigger_function
    "
    CREATE OR REPLACE FUNCTION apply_annotation_trigger_function() RETURNS TRIGGER AS $$
    BEGIN
      PERFORM apply_annotation(NEW);
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

# The following database function modifies the nodes table from a single row in annotations.
# It could be used outside the trigger, although you'd have to be sure there weren't conflicting
# rows in nodes already.  So e.g.:
#
#   DELETE FROM nodes WHERE tree_id = 1;
#   SELECT apply_annotation(annotations) FROM annotations WHERE tree_id = 1;
#
# The above might not work correctly, in that order of operations is important, but we could,
# for example, do it in ruby code like this:
#
#   Node.where(tree_id: 1).delete_all
#   Annotation.where(tree_id: 1).pluck(:id).each do |id|
#     Annotation.connection.exec_query("
#       SELECT apply_annotation(annotations) FROM annotations WHERE id = #{id};
#     ")
#   end
#
#  Of course this could be done more efficiently in a new plpgsql function using FOR.

  def apply_annotation
    # The "message" field dictates what happens to the nodes table.
    #
    # The "add" message creates two or more rows in the nodes table.  There are at least two,
    # because the first row represents a parent element, and the following rows represent
    # children of that parent element.  One "add" always equals exactly one parent and
    # one or more children.
    #
    # The "delete" message deletes rows in the nodes table.  One "delete" always deletes
    # exactly one parent and its children, therefore, deletes the result of one "add".
    #
    # The "change" message modifies exactly one row in the nodes table.
    #
    # The similarity of add/change/delete to INSERT/UPDATE/DELETE should be apparent,
    # but since these aren't strictly speaking tables, the terminology is intentionally
    # different.  For the purposes of the current database function, it's sufficient
    # to know that a row in nodes must be either a parent or a child, but not both.
    #
    # Also note that there are other messages, but they have no effect on the nodes
    # table; in other words, they are no ops for this function.
    "
    CREATE OR REPLACE FUNCTION apply_annotation(annotation xnnotations) RETURNS int AS $$
    DECLARE
      nw timestamp := now();
      parent_id int;
      parent_iid int;
      all_nodes text;
      one_node text;
      node_iid_name text[];
      node_iid int;
      node_name text;
      i int;
      parent_or_child int;
      node_id int;
    BEGIN
      CASE annotation.message
      WHEN 'add' THEN

        -- always insert exactly one parent and one or more children

        -- first iteration is always the parent, so these variables are NULL
        i := NULL;
        parent_id := NULL;
        parent_iid := NULL;

        -- legacy code for parent
        parent_or_child := 2;    

        -- get the list of nodes to insert
        SELECT value INTO all_nodes
        FROM xode_values
        WHERE id = annotation.node_value_id;

        FOREACH one_node IN ARRAY string_to_array(all_nodes, ',')
        LOOP

          -- each node is represented as a pair
          node_iid_name := string_to_array(one_node, ':');
          node_iid := node_iid_name[1]::int;
          node_name := node_iid_name[2];
          INSERT INTO xodes (
            name,
            parent_id,
            parent_iid,
            index,
            iid,
            user_id,
            task_id,
            level,
            tree_id,
            node_value_id,
            created_at,
            updated_at
          )
          VALUES (
            node_name,                  -- name/type
            parent_id,                  -- parent's primary key
            parent_iid,                 -- parent's internal id
            i,                          -- zero based index for children, null for parent
            node_iid,                   -- internal id
            annotation.user_id,
            annotation.task_id,
            parent_or_child,            -- legacy code that indicates parent or child
            annotation.tree_id,
            0,                          -- initialize with empty node value (0 rather than null)
            nw,
            nw
          )
          RETURNING id INTO node_id;

          -- set these for the children
          IF i IS NULL THEN
            i := 0;
            parent_id := node_id;
            parent_iid := node_iid;
            parent_or_child := 3;       -- legacy code for child
          ELSE
            i := i + 1;
          END IF;

        END LOOP;

        -- UPDATE xrees SET last_iid = node_iid WHERE id = annotation.tree_id;

      WHEN 'change' THEN

        -- change one node's value

        UPDATE xodes SET

          -- use the annotation node value
          node_value_id = annotation.node_value_id,

          -- changed by this user and task
          user_id = annotation.user_id,
          task_id = annotation.task_id

        -- indicate unique node with (tree_id, iid) pair rather than primary key
        WHERE tree_id = annotation.tree_id AND iid = annotation.iid;

      WHEN 'delete' THEN

        -- delete exactly one parent and its children

        DELETE FROM xodes WHERE xodes.tree_id = annotation.tree_id AND (

          annotation.iid = xodes.iid        -- parent
          OR
          annotation.iid = xodes.parent_iid  -- children
  
        );

      WHEN 'delete_all' THEN

        DELETE FROM xodes WHERE xodes.tree_id = annotation.tree_id;

      ELSE
        parent_or_child := 0; -- no op, ELSE block is required?
      END CASE;
      RETURN annotation.id;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

=begin

While annotations and nodes encode the structure of annotations, the content of the annotations
is held in node_values (currently called xode_values), which looks like this:

  integer "id"
  string "docid"
  integer "begi"
  integer "endi"
  text "value"
  text "text"
  decimal "begr", precision: 12, scale: 6
  decimal "endr", precision: 12, scale: 6
  integer "source_id"

The separation of annotation content into a separate table allows the implementation of the
content to easily change without affecting the other tables, which refer to content simply
by the id of this table.  The json object containing this content is inserted into the
database with the following function.

=end

  def create_node_value
    "
    CREATE OR REPLACE FUNCTION create_node_value(j json) RETURNS int AS $$
    DECLARE
      nw timestamp := now();
      node_value_id int;
      docid text := NULL;
      begi int := NULL;
      endi int := NULL;
      value text := NULL;
      text text := NULL;
      begr numeric := NULL;
      endr numeric := NULL;
      source_id int := NULL;
    begin

      -- 0, rather than NULL, indicates an empty value
      -- no record with id = 0 exists

      IF j IS NULL THEN
        RETURN 0;
      END IF;

      -- what if everything here is null?
      -- right now an insertion would occur

      IF json_typeof(j->'value') IS NOT NULL THEN             -- 'value' key is present

        IF json_typeof(j->'value') = 'null' THEN   -- this is considered empty
          RETURN 0;
        END IF;

        -- note here that in both cases ->> forces value to be string
        IF json_typeof(j->'value') = 'array' THEN
          value := regexp_replace(j->>'value', '[\\[\\]\\s]', '', 'g');
        ELSE
          value := j->>'value';
        END IF;

      END IF;

      IF json_typeof(j->'docid') IS NOT NULL THEN
        docid := j->>'docid';
      END IF;


      -- note that json doesn't distinguish between int and real

      IF json_typeof(j->'beg') IS NOT NULL THEN
        IF json_typeof(j->'beg') = 'number' THEN
          IF position('.' in j->>'beg') > 0 OR j->>'type' = 'real' THEN
            begr := j->'beg';  -- real
          ELSE
            begi := j->'beg';  -- int
          END IF;
        END IF;
      END IF;

      IF json_typeof(j->'end') IS NOT NULL THEN
        IF json_typeof(j->'end') = 'number' THEN
          IF position('.' in j->>'end') > 0 OR j->>'type' = 'real' THEN
            endr := j->'end';  -- real
          ELSE
            endi := j->'end';  -- int
          END IF;
        END IF;
      END IF;

      IF json_typeof(j->'source_id') IS NOT NULL THEN
        source_id := j->'source_id';
      END IF;

      IF json_typeof(j->'points') IS NOT NULL THEN         -- array of pairs of integers
        value := regexp_replace(
          regexp_replace(
            regexp_replace(j->>'points', '\\s', '', 'g'),  -- remove whitespace
            '\\],\\[', ';', 'g'                            -- use ; between pairs
          ),
          '[\\[\\]\"]', '', 'g'                            -- remove outermost brackets
        );
      END IF;

      INSERT INTO xode_values (
        docid,
        begi,
        endi,
        value,
        text,
        begr,
        endr,
        source_id,
        created_at,
        updated_at
      )
      VALUES (
        docid,
        begi,
        endi,
        value,
        text,
        begr,
        endr,
        source_id,
        nw,
        nw
      ) RETURNING id INTO node_value_id;
      RETURN node_value_id;
    END;
    $$ LANGUAGE plpgsql;
    "
    # Project.connection.exec_query("select create_node_value('{ \"points\": [[1,1], [2,2], [3,3]] }')").entries.to_s
    # raise Project.connection.exec_query("select * from xode_values order by id desc limit 1").entries.to_s
    # Project.connection.exec_query('drop trigger apply_annotations_trigger on xnnotations;')
    # Project.connection.exec_query('drop function if exists apply_annotations();')
    # Project.connection.exec_query('drop function if exists apply_annotations_with_row(journal annotation_journals);')
    # Project.connection.exec_query("
  end

  def output_insert_node_trigger
    # "
    # CREATE OR REPLACE TRIGGER output_insert_node_trigger
    "
    CREATE TRIGGER output_insert_node_trigger
    AFTER INSERT ON xodes
    FOR EACH ROW EXECUTE FUNCTION output_insert_node_trigger_function();
    "
  end

# The trigger function wraps another function so that the same logic can be done without
# relying on the trigger:

  def output_insert_node_trigger_function
    "
    CREATE OR REPLACE FUNCTION output_insert_node_trigger_function() RETURNS TRIGGER AS $$
    BEGIN
      PERFORM output_insert_node(NEW);
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

# The following database function modifies the nodes table from a single row in annotations.

  def output_insert_node(arc_task_ids)
    "
    CREATE OR REPLACE FUNCTION output_insert_node(node xodes) RETURNS int AS $$
    DECLARE
      tablename text;
      x text;
    BEGIN

      IF node.parent_iid IS NULL AND node.name != 'NListItem' THEN

        CASE node.task_id
        WHEN 127, 129 THEN
          tablename := regexp_replace(node.name, 'ListItem$', 'os');
        ELSE
          tablename := regexp_replace(node.name, 'ListItem$', 's');
        END CASE;

        EXECUTE 'INSERT INTO ' || tablename || ' (tree_id, iid) VALUES ( ' || node.tree_id  || ' , ' || node.iid || ' ) ';

      END IF;

      RETURN node.id;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

  def output_update_node_trigger
    # "
    # CREATE OR REPLACE TRIGGER output_update_node_trigger
    "
    CREATE TRIGGER output_update_node_trigger
    AFTER UPDATE ON xodes
    FOR EACH ROW EXECUTE FUNCTION output_update_node_trigger_function();
    "
  end

# The trigger function wraps another function so that the same logic can be done without
# relying on the trigger:

  def output_update_node_trigger_function
    "
    CREATE OR REPLACE FUNCTION output_update_node_trigger_function() RETURNS TRIGGER AS $$
    BEGIN
      PERFORM output_update_node(NEW);
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

# The following database function modifies the nodes table from a single row in annotations.

  def output_update_node_old
    "
    CREATE OR REPLACE FUNCTION output_update_node(node xodes) RETURNS int AS $$
    DECLARE
      tablename text;
      parent_name text;
      ndocid text;
      nbegr numeric;
      nendr numeric;
      nvalue text;
      where_string text;
    BEGIN

      IF node.parent_id IS NOT NULL THEN
        SELECT name INTO parent_name
        FROM xodes
        WHERE id = node.parent_id;

        tablename := regexp_replace(parent_name, 'ListItem$', 's');

        where_string := ' WHERE tree_id = '
          || node.tree_id
          || ' AND iid = '
          || node.parent_iid;

        IF node.node_value_id = 0 THEN

          CASE node.name
          WHEN 'Segment' THEN

            EXECUTE 'UPDATE '
              || tablename
              || ' SET docid = NULL, begr = NULL, endr = NULL'
              || where_string;

          WHEN 'Transcription' THEN

            EXECUTE 'UPDATE '
              || tablename
              || ' SET text = NULL'
              || where_string;

          WHEN 'Speaker' THEN

            EXECUTE 'UPDATE '
              || tablename
              || ' SET speaker = NULL'
              || where_string;

          WHEN 'Section' THEN

            EXECUTE 'UPDATE '
              || tablename
              || ' SET section = NULL'
              || where_string;
  
          WHEN 'BegSeg' THEN

            EXECUTE 'UPDATE '
              || tablename
              || ' SET begseg = NULL'
              || where_string;
    
          WHEN 'EndSeg' THEN

            EXECUTE 'UPDATE '
              || tablename
              || ' SET endseg = NULL'
              || where_string;

          ELSE

            ndocid := 'noop';
  
          END CASE;

        ELSE

          CASE node.name
          WHEN 'Segment' THEN

            SELECT docid, begr, endr INTO ndocid, nbegr, nendr
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE 'UPDATE '
              || tablename
              || ' SET docid = '
              || coalesce(quote_literal(ndocid),'e')
              || ', begr = '
              || coalesce(nbegr,0.001)
              || ', endr = '
              || coalesce(nendr,0.001)
              || where_string;
            
          WHEN 'Transcription' THEN

            SELECT value INTO nvalue
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE 'UPDATE '
              || tablename
              || ' SET text = '
              || quote_literal(nvalue)
              || where_string;

          WHEN 'Speaker' THEN

            SELECT value INTO nvalue
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE 'UPDATE '
              || tablename
              || ' SET speaker = '
              || quote_literal(nvalue)
              || where_string;

          WHEN 'Section' THEN

            SELECT value INTO nvalue
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE 'UPDATE '
              || tablename
              || ' SET section = '
              || quote_literal(nvalue)
              || where_string;
  
          WHEN 'BegSeg' THEN

            SELECT CAST(value AS INTEGER) INTO nvalue
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE 'UPDATE '
              || tablename
              || ' SET begseg = '
              || nvalue
              || where_string;
    
          WHEN 'EndSeg' THEN

            SELECT CAST(value AS INTEGER) INTO nvalue
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE 'UPDATE '
              || tablename
              || ' SET endseg = '
              || nvalue
              || where_string;

          ELSE

            ndocid := 'noop';
    
          END CASE;

        END IF;

      END IF;
      
      RETURN node.id;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

  def output_update_node(arc_task_ids)
    "
    CREATE OR REPLACE FUNCTION output_update_node(node xodes) RETURNS int AS $$
    DECLARE
      tablename text;
      parent_name text;
      ndocid text;
      nbegi bigint;
      nendi bigint;
      nbegr numeric(12,6);
      nendr numeric(12,6);
      nvalue text;
      nvi bigint;
      update_string text;
      where_string text;
      where_string_beg text;
      where_string_end text;
    BEGIN

      IF node.parent_id IS NOT NULL THEN
        SELECT name INTO parent_name
        FROM xodes
        WHERE id = node.parent_id;

        tablename := regexp_replace(parent_name, 'ListItem$', 's');

        update_string := 'UPDATE ' || tablename || ' SET ';
        where_string := ' WHERE tree_id = ' || node.tree_id || ' AND ';
        where_string_beg := where_string || 'begn = ' || node.parent_iid;
        where_string_end := where_string || 'endn = ' || node.parent_iid;
        where_string     := where_string || 'iid = '  || node.parent_iid;

        IF node.node_value_id = 0 THEN

          CASE node.name
          WHEN 'Arc' THEN

            EXECUTE update_string || 'begn = NULL, endn = NULL, btime = NULL, etime = NULL' || where_string;

          WHEN 'N' THEN

            EXECUTE 'UPDATE segments SET btime = NULL ' || where_string_beg;
            EXECUTE 'UPDATE segments SET etime = NULL ' || where_string_end;
            EXECUTE 'UPDATE sections SET btime = NULL ' || where_string_beg;
            EXECUTE 'UPDATE sections SET etime = NULL ' || where_string_end;

          WHEN 'Segment' THEN

            EXECUTE update_string || 'docid = NULL, begr = NULL, endr = NULL' || where_string;
    
          WHEN 'Transcription' THEN
    
            EXECUTE update_string || 'text = NULL' || where_string;

          ELSE

            EXECUTE update_string || node.name || ' = NULL' || where_string;

          END CASE;

        ELSE

          CASE node.name
          WHEN 'Arc' THEN

            SELECT begi, endi INTO nbegi, nendi
            FROM xode_values
            WHERE id = node.node_value_id;

            update_string := update_string || 'begn = ' || nbegi || ', endn = ' || nendi;

            SELECT node_value_id INTO nvi FROM xodes WHERE tree_id = node.tree_id AND iid = nbegi + 1;
            IF nvi = 0 THEN
              update_string := update_string || ', btime = NULL';
            ELSE
              SELECT begr INTO nbegr FROM xode_values WHERE id = nvi;
              IF nbegr IS NULL THEN
                update_string := update_string || ', btime = NULL';
              ELSE
                update_string := update_string || ', btime = ' || nbegr;
              END IF;
            END IF;

            SELECT node_value_id INTO nvi FROM xodes WHERE tree_id = node.tree_id AND iid = nendi + 1;
            IF nvi = 0 THEN
              update_string := update_string || ', etime = NULL';
            ELSE
              SELECT begr INTO nbegr FROM xode_values WHERE id = nvi;
              IF nbegr IS NULL THEN
                update_string := update_string || ', etime = NULL';
              ELSE
                update_string := update_string || ', etime = ' || nbegr;
              END IF;
            END IF;

            EXECUTE update_string || where_string;

          WHEN 'N' THEN

            SELECT begr INTO nbegr
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE 'UPDATE segments SET btime = ' || nbegr || where_string_beg;
            EXECUTE 'UPDATE segments SET etime = ' || nbegr || where_string_end;
            EXECUTE 'UPDATE sections SET btime = ' || nbegr || where_string_beg;
            EXECUTE 'UPDATE sections SET etime = ' || nbegr || where_string_end;

          WHEN 'Segment' THEN

            SELECT docid, begr, endr INTO ndocid, nbegr, nendr
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE update_string || 'docid = ' || coalesce(quote_literal(ndocid),'e') || ', begr = ' || coalesce(nbegr,0.001) || ', endr = ' || coalesce(nendr,0.001) || where_string;

          WHEN 'Transcription' THEN

            SELECT value INTO nvalue
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE update_string || 'text' || ' = ' || quote_literal(nvalue) || where_string;
                  
          WHEN 'BegSeg', 'EndSeg' THEN

            SELECT CAST(value AS INTEGER) INTO nvalue
            FROM xode_values
            WHERE id = node.node_value_id;

            EXECUTE update_string || node.name || ' = ' || nvalue || where_string;
  
          ELSE

              SELECT value INTO nvalue
              FROM xode_values
              WHERE id = node.node_value_id;

              EXECUTE update_string || node.name || ' = ' || quote_literal(nvalue) || where_string;

          END CASE;

        END IF;

      END IF;
      
      RETURN node.id;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

  def output_delete_node_trigger
    # "
    # CREATE OR REPLACE TRIGGER output_delete_node_trigger
    "
    CREATE TRIGGER output_delete_node_trigger
    AFTER DELETE ON xodes
    FOR EACH ROW EXECUTE FUNCTION output_delete_node_trigger_function();
    "
  end

# The trigger function wraps another function so that the same logic can be done without
# relying on the trigger:

  def output_delete_node_trigger_function
    "
    CREATE OR REPLACE FUNCTION output_delete_node_trigger_function() RETURNS TRIGGER AS $$
    BEGIN
      PERFORM output_delete_node(OLD);
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

# The following database function modifies the nodes table from a single row in annotations.

  def output_delete_node(arc_task_ids)
    "
    CREATE OR REPLACE FUNCTION output_delete_node(node xodes) RETURNS int AS $$
    DECLARE
      tablename text;
    BEGIN

      IF node.parent_id IS NULL AND node.name != 'NListItem' THEN

        tablename := regexp_replace(node.name, 'ListItem$', 's');

        EXECUTE 'DELETE FROM ' || tablename || ' WHERE tree_id = ' || node.tree_id || ' AND iid = ' || node.iid;

      END IF;

      RETURN node.id;
    END;
    $$ LANGUAGE plpgsql;
    "
  end

  def annotations_setup(arc_task_ids)
    %w[
      create_output_tables2
    ].each do |x|
      send(x).flatten.each { |x| Project.connection.exec_query(x) }
    end
  [
    output_insert_node(arc_task_ids),
    output_insert_node_trigger_function,
    output_insert_node_trigger,
    output_update_node(arc_task_ids),
    output_update_node_trigger_function,
    output_update_node_trigger,
    output_delete_node(arc_task_ids),
    output_delete_node_trigger_function,
    output_delete_node_trigger
  ].each do |x|
    Project.connection.exec_query(x)
  end
  # return
  %w[
    create_node_value
    create_annotations
    create_annotations_trigger_function
    create_annotations_trigger
    apply_annotation
    apply_annotation_trigger_function
    apply_annotation_trigger
  ].each do |x|
    Project.connection.exec_query(send(x))
  end
end


  def test
    Xode.where(tree_id: 1).destroy_all
    j = AnnotationJournal.create(user_id: 1, task_id: 1, kit_id: 1, tree_id: 1, json: AnnotationJournal.last.json)
    # raise XodeValue.find(XodeValue.last.id-1).inspect
    # raise Xnnotation.find(Xnnotation.last.id-1).inspect
    raise Xode.last.inspect
    Project.connection.exec_query('drop function if exists last_annotation_journal();')
    Project.connection.exec_query('
    ')
    Project.connection.exec_query('drop function if exists tf();')
    Project.connection.exec_query('
    create function tf() returns table(idx bigint, namex varchar) as $$
    declare
      c integer;
      row xnnotation%ROWTYPE;
    begin
      return query select id, name from projects;
    end;
    $$ LANGUAGE plpgsql;
    ')
    raise Project.connection.exec_query('select tf();').entries.to_s
    raise Project.connection.exec_query("
      SELECT
      routine_name
      FROM 
      information_schema.routines
      WHERE 
      routine_type = 'FUNCTION'
      AND
      routine_schema = 'public';
    ").entries.to_s
    # end
    
  end

  def create_output_tables2
    [
    "
    CREATE TABLE segments (
      id bigint NOT NULL,
      tree_id bigint NOT NULL,
      iid bigint NOT NULL,
      begn bigint,
      endn bigint,
      btime numeric(12,6),
      etime numeric(12,6),
      text text,
      speaker text
    );
    ", "
    CREATE SEQUENCE segments_id_seq
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1;
    ", "
    ALTER TABLE ONLY segments ALTER COLUMN id SET DEFAULT nextval('segments_id_seq'::regclass);
    ", "
    ALTER TABLE ONLY segments ADD CONSTRAINT segments_pkey PRIMARY KEY (id);
    ", "
    CREATE UNIQUE INDEX index_segments_on_tree_id_and_iid ON segments USING btree (tree_id, iid);
    ", "
    CREATE        INDEX index_segments_on_tree_id_and_begn ON segments USING btree (tree_id, begn);
    ", "
    CREATE        INDEX index_segments_on_tree_id_and_endn ON segments USING btree (tree_id, endn);
    ", "
    CREATE TABLE sections (
      id bigint NOT NULL,
      tree_id bigint NOT NULL,
      iid bigint NOT NULL,
      begn bigint,
      endn bigint,
      btime numeric(12,6),
      etime numeric(12,6),
      name text
    );
    ", "
    CREATE SEQUENCE sections_id_seq
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1;
    ", "
    ALTER TABLE ONLY sections ALTER COLUMN id SET DEFAULT nextval('sections_id_seq'::regclass);
    ", "
    ALTER TABLE ONLY sections ADD CONSTRAINT sections_pkey PRIMARY KEY (id);
    ", "
    CREATE UNIQUE INDEX index_sections_on_tree_id_and_iid ON sections USING btree (tree_id, iid);
    ", "
    CREATE        INDEX index_sections_on_tree_id_and_begn ON sections USING btree (tree_id, begn);
    ", "
    CREATE        INDEX index_sections_on_tree_id_and_endn ON sections USING btree (tree_id, endn);

    "
    ]
  end

  def drop_output_tables2
    [
      "
      DROP TABLE segments;
      ", "
      DROP SEQUENCE segments_id_seq;
      ", "
      DROP TABLE sections;
      ", "
      DROP SEQUENCE sections_id_seq;
      "
  ]
end

end

