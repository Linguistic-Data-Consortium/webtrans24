import { getp, postp, deletep } from '../lib/ldcjs/getp';
const get_projects = () => getp('/projects');
const get_project = (x) => getp(`/projects/${x}`);
const create_project = (x) => postp( '/projects', x );
const delete_project = (x) => deletep( `/projects/${x}` );
// const get_tasks = () => getp('/tasks');
const get_task = (project_id, x) => getp(`/projects/${project_id}/tasks/${x}`);
const create_task = (project_id, x) => postp( `/projects/${project_id}/tasks`, x );
const delete_task = (project_id, x) => deletep( `/projects/${project_id}/tasks/${x}` );
function create_action(x){
  const y = {
    user_id: window.ldc.vars.user_id,
    task_id: window.ldc.vars.task_id,
    kit_id: window.ldc.vars.kit_id,
    name: x,
    client_time: (new Date()).getTime()
  };
  postp( '/actions', y );
}
export {
  get_projects,
  get_project,
  create_project,
  delete_project,
  // get_tasks,
  get_task,
  create_task,
  delete_task,
  create_action
}
