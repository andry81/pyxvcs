import os, sys, shutil, inspect
#from datetime import datetime

SOURCE_FILE = os.path.abspath(inspect.getsourcefile(lambda:0)).replace('\\','/')
SOURCE_DIR = os.path.dirname(SOURCE_FILE)

# portable import to the global space
sys.path.append(SOURCE_DIR + '/tools/tacklelib')
import tacklelib as tkl

tkl.tkl_init(tkl)

# cleanup
del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
sys.path.pop()


tkl_declare_global('CONFIGURE_DIR', sys.argv[1].replace('\\', '/') if len(sys.argv) >= 2 else '')

# format: [(<header_str>, <stderr_str>), ...]
tkl_declare_global('g_registered_ignored_errors', []) # must be not empty value to save the reference

# basic initialization, loads `config.private.yaml`
tkl_source_module(SOURCE_DIR, '__init__.xsh')

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

if not os.path.isdir(CONFIGURE_ROOT):
  raise Exception('CONFIGURE_ROOT directory does not exist: `{0}`'.format(CONFIGURE_ROOT))

if not os.path.isdir(CONFIGURE_DIR):
  raise Exception('CONFIGURE_DIR directory does not exist: `{0}`'.format(CONFIGURE_DIR))

#try:
#  os.mkdir(os.path.join(CONFIGURE_DIR, '.log'))
#except:
#  pass

def get_supported_scm_list():
  return ['svn', 'git']

def validate_vars(configure_dir):
  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    exit(1)

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    exit(2)

  return (configure_dir)

def configure(configure_dir):
  print("configure: entering `{0}`".format(configure_dir))

  with tkl.OnExit(lambda: print("configure: leaving `{0}`\n---".format(configure_dir))):
    if configure_dir == '':
      print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
      exit(1)

    configure_dir = validate_vars(configure_dir)

    try:
      # load at first from a local config directory
      for config_dir in [configure_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_dir]:
        if not os.path.exists(config_dir):
          continue
        if os.path.isfile(os.path.join(config_dir, 'git_repos.lst.in')):
          shutil.copyfile(os.path.join(config_dir, 'git_repos.lst.in'), os.path.join(config_dir, 'git_repos.lst')),
        if os.path.isfile(os.path.join(config_dir, 'config.yaml.in')):
          shutil.copyfile(os.path.join(config_dir, 'config.yaml.in'), os.path.join(config_dir, 'config.yaml')),
        if os.path.isfile(os.path.join(config_dir, 'config.env.yaml.in')):
          shutil.copyfile(os.path.join(config_dir, 'config.env.yaml.in'), os.path.join(config_dir, 'config.env.yaml')),
    except:
      # `exit` with the parentheses to workaround the issue:
      # `source` xsh file with try/except does hang`:
      # https://github.com/xonsh/xonsh/issues/3301
      exit(255)

    # load at first from a local config directory
    yaml_global_vars_pushed = False
    yaml_environ_vars_pushed = False
    for config_dir in [configure_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_dir]:
      if not os.path.exists(config_dir):
        continue

      if os.path.isfile(config_dir + '/config.yaml.in'):
        # save all old variable values and remember all newly added variables as a new stack record
        if not yaml_global_vars_pushed:
          yaml_push_global_vars()
          yaml_global_vars_pushed = True
        yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
          search_by_global_pred_at_third = lambda var_name: getglobalvar(var_name))

      if os.path.isfile(config_dir + '/config.env.yaml.in'):
        # save all old variable values and remember all newly added variables as a new stack record
        if not yaml_environ_vars_pushed:
          yaml_push_environ_vars()
          yaml_environ_vars_pushed = True
        yaml_load_config(config_dir, 'config.env.yaml', to_globals = False, to_environ = True,
          search_by_environ_pred_at_third = lambda var_name: getglobalvar(var_name))

    # Read all `*.HUB_ABBR` and `*.PROJECT_PATH_LIST` variables to find out
    # what vcs command scripts to generate and where.
    scm_list = get_supported_scm_list()
    tmpl_cmdop_files_tuple_list = []

    for scm in scm_list:
      for key, value in g_yaml_globals.expanded_items():
        if key.startswith(scm.upper()) and key.endswith('.HUB_ABBR'):
          scm_token_upper = key[:key.find('.')].upper()

          configure_relpath = os.path.relpath(configure_dir, CONFIGURE_ROOT).replace('\\', '/')
          if len(configure_relpath) > 0 and configure_relpath != '.':
            project_path_list = g_yaml_globals.get_expanded_value(scm_token_upper + '.PROJECT_PATH_LIST')
            is_configure_dir_in_project_path_list = False
            for project_path in project_path_list:
              is_configure_dir_in_project_path_list = tkl.compare_file_paths(configure_relpath, project_path)
              if is_configure_dir_in_project_path_list:
                break

            if not is_configure_dir_in_project_path_list:
              continue

          for dirpath, dirs, files in os.walk(TMPL_CMDOP_FILES_DIR):
            for file in files:
              if tkl.is_file_path_beginswith(file, '{HUB}~' + scm + '~') and \
                 tkl.is_file_path_endswith(file, '.in'):
                tmpl_cmdop_files_tuple_list.append((scm_token_upper, file, file[:file.rfind('.')].format(HUB = value)))
            dirs.clear() # not recursively

    # generate vcs command scripts
    for tmpl_cmdop_files_tuple in tmpl_cmdop_files_tuple_list:
      scm_token_upper = tmpl_cmdop_files_tuple[0]
      in_file_name = tmpl_cmdop_files_tuple[1]
      out_file_name = tmpl_cmdop_files_tuple[2]
      in_file_path = os.path.join(TMPL_CMDOP_FILES_DIR, in_file_name).replace('\\', '/')
      out_file_path = os.path.join(configure_dir, out_file_name).replace('\\', '/')
      with open(in_file_path, 'rt') as in_file, open(out_file_path, 'wt') as out_file:
        in_file_content = in_file.read()
        out_file.write(in_file_content.format(SCM_TOKEN = scm_token_upper))

    ret = 0

    for dirpath, dirs, files in os.walk(configure_dir):
      for dir in dirs:
        # ignore directories beginning by '.'
        if str(dir)[0:1] == '.':
          continue
        # ignore common directories
        if str(dir) in ['_common']:
          continue
        ## ignore directories w/o config.vars.in and config.yaml.in files
        #if not (os.path.isfile(os.path.join(dirpath, dir, 'config.vars.in')) and
        #   os.path.isfile(os.path.join(dirpath, dir, 'config.yaml.in'))):
        #  continue
        if os.path.isfile(os.path.join(dirpath, dir, 'config.yaml.in')):
          ret = configure(os.path.join(dirpath, dir).replace('\\', '/'))
      dirs.clear() # not recursively

    if yaml_environ_vars_pushed:
      # remove previously added variables and restore previously changed variable values
      yaml_pop_environ_vars(True)

    if yaml_global_vars_pushed:
      # remove previously added variables and restore previously changed variable values
      yaml_pop_global_vars(True)

  return ret

def on_main_exit():
  if len(g_registered_ignored_errors) > 0:
    print('- Registered ignored errors:')
    for registered_ignored_error in g_registered_ignored_errors:
      print(registered_ignored_error[0])
      print(registered_ignored_error[1])
      print('---')

def main(configure_root, configure_dir):
  with tkl.OnExit(on_main_exit):
    configure_dir = validate_vars(configure_dir)

    configure_relpath = os.path.relpath(configure_dir, configure_root).replace('\\', '/')
    configure_relpath_comps = configure_relpath.split('/')
    num_comps = len(configure_relpath_comps)

    # load `config.yaml` from `configure_root` up to `configure_dir` (excluded) directory
    if num_comps > 1:
      for config_dir in [configure_root + '/' + LOCAL_CONFIG_DIR_NAME, configure_root]:
        if not os.path.exists(config_dir):
          continue

        if os.path.exists(config_dir + '/config.yaml.in'):
          yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
            search_by_global_pred_at_third = lambda var_name: getglobalvar(var_name))

      for i in range(num_comps-1):
        configure_parent_dir = os.path.join(configure_root, *configure_relpath_comps[:i+1]).replace('\\', '/')

        for config_dir in [configure_parent_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_parent_dir]:
          if not os.path.exists(config_dir):
            continue

          if os.path.exists(config_dir + '/config.yaml.in'):
            yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
              search_by_global_pred_at_third = lambda var_name: getglobalvar(var_name))

    # load `config.env.yaml` from `configure_root` up to `configure_dir` (excluded) directory
    if num_comps > 1:
      for config_dir in [configure_root + '/' + LOCAL_CONFIG_DIR_NAME, configure_root]:
        if not os.path.exists(config_dir):
          continue

        if os.path.exists(config_dir + '/config.env.yaml.in'):
          yaml_load_config(config_dir, 'config.env.yaml', to_globals = False, to_environ = True,
            search_by_environ_pred_at_third = lambda var_name: getglobalvar(var_name))

      for i in range(num_comps-1):
        configure_parent_dir = os.path.join(configure_root, *configure_relpath_comps[:i+1]).replace('\\', '/')

        for config_dir in [configure_parent_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_parent_dir]:
          if not os.path.exists(config_dir):
            continue

          if os.path.exists(config_dir  + '/config.env.yaml.in'):
            yaml_load_config(config_dir , 'config.env.yaml', to_globals = False, to_environ = True,
              search_by_environ_pred_at_third = lambda var_name: getglobalvar(var_name))

    configure(configure_dir)

# CAUTION:
#   Temporary disabled because of issues in the python xonsh module.
#   See details in the `README_EN.python_xonsh.known_issues.txt` file.
#
#@(pcall, main, CONFIGURE_ROOT, CONFIGURE_DIR) | @(CONTOOLS_ROOT + '/wtee.exe', CONFIGURE_DIR + '/.log/' + os.path.splitext(os.path.split(__file__)[1])[0] + '.' + datetime.now().strftime("%Y'%m'%d_%H'%M'%S''%f")[:-3])

# NOTE:
#   Logging is implemented externally to the python.
#
if __name__ == '__main__':
  main(CONFIGURE_ROOT, CONFIGURE_DIR)
