import { getp, postp, deletep, patchp } from '../lib/ldcjs/getp';
const controller_actions = {}
const models = [
  'project',
  'kit_type',
  'feature',
  'workflow',
  'group'
];
for(const m of models){
  const a = {};
  controller_actions[m] = a;
  const base = `/${m}s`;
  a.get_all = () => getp(base);
  a.get_one = x => getp(`${base}/${x}`);
  a.create = x => postp(base, x);
  a.delete = x => deletep(`${base}/${x}`);
  a.patch = (x, y) => patchp(`${base}/${x}`, y);
}
// const get_tasks = () => getp('/tasks');
controller_actions.project_user = {};
controller_actions.project_user.not_in = (x, y) => getp(`/projects/${x}/users_not_in_project?term=${y}`);
controller_actions.project_user.create = (x) => postp('/project_users', x);
controller_actions.project_user.delete = (x) => deletep(`/project_users/${x}`);
controller_actions.project_user.patch = (x, y) => patchp(`/project_users/${x}`, y);
controller_actions.task = {};
controller_actions.task.get_one = (project_id, x) => getp(`/projects/${project_id}/tasks/${x}`);
controller_actions.task.create = (project_id, x) => postp( `/projects/${project_id}/tasks`, x );
controller_actions.task.delete = (x) => deletep(`/projects/0/tasks/${x}`);
controller_actions.task.patch = (x, y) => patchp(`/projects/0/tasks/${x}`, y);
controller_actions.task_user = {};
controller_actions.task_user.get_one = (x) => getp(`/task_users/${x}`);
controller_actions.task_user.create = (x) => postp('/task_users', x);
controller_actions.task_user.delete = (x) => deletep(`/task_users/${x}`);
controller_actions.task_user.patch = (x, y) => patchp(`/task_users/${x}`, y);
controller_actions.group_user = {};
controller_actions.group_user.not_in = (x, y) => getp(`/groups/${x}/users_not_in?term=${y}`);
controller_actions.group_user.create = (x) => postp('/group_users', x);
controller_actions.group_user.delete = (x) => deletep(`/group_users/${x}`);
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
function create_tasks(){}
function create_task(){}
function delete_task(){}
function get_task(){}
function get_projects(){}
function get_project(){}
function delete_project(){}
function create_project(){}
export {
  controller_actions,
  create_action,
  create_tasks,
  create_task,
  delete_task,
  get_task,
  create_project,
  delete_project,
  get_project,
  get_projects
}
