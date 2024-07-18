<script>
  import { term } from './helpers.js'
</script>

<h3 class="text-2xl font-bold mb-2">Project Management Features</h3>

<p class="mb-2">
  Project management features are built in.  A {@html term("project")} is a logical
  division of work and people, and a {@html term("task")} is a subdivision of a project.
  Users can be added to projects, and can be members of multiple projects.  The members
  of a project can then be added to tasks within the project.  In this way, the work
  available on the system can be organized.  Each user's home page shows a list
  of tasks that they're members of, and they can begin work from there.
</p>

<p class="mb-2">
  A {@html term("kit")} is a unit of work within a {@html term("task")}.  Kits can be
  assigned to users that are members of the same task.  A user works on a kit
  until it's complete, or until they decide to switch to another task.
</p>
