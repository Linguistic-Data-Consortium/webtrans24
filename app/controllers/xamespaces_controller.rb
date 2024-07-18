class XamespacesController < ApplicationController

  before_action :authenticate

  def index
    arc_task_ids = []
    helpers.annotations_setup(arc_task_ids)
    respond_to do |format|
      format.json do
        render json: (
          if project_manager?
            if params[:task_id]
              if params[:kit_uid]
                tree_id = [ Kit.where(uid: params[:kit_uid]).first&.tree_id ].compact
              else
                tree_id = Kit.where(task_id: params[:task_id], state: :done).last(1).map { |x| x.tree_id }
              end
              if params[:output] == 'annotations'
                rows = Xnnotation.where(tree_id: tree_id).map { |x|
                  {
                    transaction_id: x.transaction_id,
                    id: x.id,
                    parent_id: x.parent_id,
                    tree_id: x.tree_id,
                    iid: x.iid,
                    node_value_id: x.node_value_id,
                    message: x.message
                  }
                }
              elsif params[:output] == 'nodes'
                rows = Xode.where(tree_id: tree_id).order(:id).map { |x|
                  {
                    id: x.id,
                    tree_id: x.tree_id,
                    iid: x.iid,
                    name: x.name,
                    parent_id: x.parent_id,
                    parent_iid: x.parent_iid,
                    node_value_id: x.node_value_id
                  }
                }
              else
                # rows = Xnnotation.connection.exec_query("select * from \"CamioTextLocalizationZoneList\" where tree_id = #{tree_id}").entries
                rows = Xnnotation.connection.exec_query("select * from \"#{params[:output]}\" where tree_id in (#{tree_id.join(',')})").entries
              end
              {
                columns: (rows.first || {}).keys,
                rows: rows
              }
            else
              XlassDef.sorted.all.map(&:attributes)
            end
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def query(q)
    logger.info q
    XlassDef.connection.exec_query(q)
  end

  def show
    respond_to do |format|
      format.json do
        render json: (
          if params[:output] and lead_annotator?
            output_table_info
          elsif project_manager?
            XlassDef.find(params[:id]).basic_info
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def output_table_info
    if params[:task_id]
      id = Kit.where(task_id: params[:task_id]).first&.tree&.class_def_id
      if id
        @class_def = XlassDef.find_by_name(ClassDef.find(id).name)
        # @class_def = XlassDef.find_by_name(ClassDef.find(525).name)
      else
        return []
      end
    else
      @class_def = XlassDef.find(params[:id])
    end
    lists_in_tool = NodeList.where(class_def_id: @class_def.id).map { |x| "#{@class_def.name}#{x.name}" }
    if params[:output] == 'one'
      lists_in_tool
    elsif params[:output].in? lists_in_tool
      look_up_columns
    else
      couldnt_find_table_error
    end
  end
  
  def look_up_columns
    look_up_table
    # { found: query("select * from #{table}").to_a }
    b = @table.in? @found_tables
    @class_def.create_specific_table params[:output] if !b
    @actual_columns = query("select column_name from information_schema.columns where table_name = '#{@table}'").rows.flatten
    if params[:count]
      count_table
    elsif params[:check]
      check_table
    else
      get_rows
    end
  end

  def check_table
    ok = 0
    notok = 0
    name = @table.sub(@class_def.name, '')
    expected = NodeList.where(class_def_id: @class_def.id, name: name).first.children.split(' ').join(',')
    name += 'Item'
    Tree.includes(:xodes).where(class_def_id: @class_def.id).each do |tree|
      isok = true
      tree.xodes.select { |x| x.name == name }.each do |x|
        actual = tree.xodes.select { |y| y.parent_id == x.id }.map { |x| x.name }.join(',')
        if actual != expected
          isok = false
          break
        end
      end
      if isok
        ok += 1
      else
        notok += 1
      end
    end
    { ok: ok, notok: notok }
  end

  def get_rows
    # last = Tree.where(class_def_id: @class_def.id).pluck(:id).first(100)
    # query("delete from #{@table} where tree_id in (#{last.join(',')})")
    # last.each do |id|
    #   query("insert into #{@table} (tree_id) values (#{id})")
    # end
    r = query("select * from #{@table}").entries
    { columns: @actual_columns, rows: r }
  end

  def count_table
    r = query("select count(*) from #{@table}").rows.first
    t = @table.sub @class_def.name, ''
    c = NodeList.where(class_def_id: @class_def.id, name: t).first.children.split(' ')
    { columns: @actual_columns, rows: [], count: r, defined: c }
  end

  def look_up_table
    @found_tables = query("select table_name from information_schema.tables").rows.flatten
    @table = params[:output]
    @table = @table.downcase if 'pg_type'.in? @found_tables
  end

  def couldnt_find_table_error
    look_up_table
    { columns: [ 'table' ], rows: ([ @table ] + @found_tables).map { |x| { table: x } } }
  end

  def create
    respond_to do |format|
      format.json do
        render json: (
          if not project_manager?
            { error: "Only a project manager can create a namespace." }
          else
            class_def = XlassDef.new class_def_params
            if class_def.save
              class_def.attributes
            else
              { error: class_def.errors.full_messages }
            end
          end
        )
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        render json: (
          if not project_manager?
            { error: "Only a project manager can edit the class_def." }
          else
            class_def = XlassDef.find(params[:id])
            if class_def.update class_def_params
              if @def
                o = JSON.parse(@def)['classes']
                NodeList.where(class_def_id: class_def.id).each do |x|
                  next if x.name.in? o.keys
                  x.destroy
                end
                o.each do |k, v|
                  NodeList.where(class_def_id: class_def.id, name: k).first_or_create.update(children: v['children'].join(' '))
                end
              end
              class_def.attributes
            else
              { error: class_def.errors.full_messages }
            end
          end
        )
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        render json: (
          if not project_manager?
            { error: "Only a project manager can delete the class_def." }
          else
            class_def = XlassDef.find(params[:id])
            class_def.destroy
            { deleted: "class_def: #{class_def.name} has been deleted." }
          end
        )
      end
    end
  end

  private

  def class_def_params
    @def = params['xamespace']['def']
    params['xamespace']['def'] = ''
    params.require(:xamespace).permit(:name, :def)
  end

end
