* README_EN.txt
* 2019.12.31
* pyxvcs

1. DESCRIPTION
2. DIRECTORY DEPLOY STRUCTURE
3. FEATURES
3.1. SVN-to-GIT
4. PREREQUISITES
5. CONFIGURE
6. USAGE
6.1. Mirroring (merging) from SVN to GIT
7. SSH+SVN/PLINK SETUP
8. KNOWN ISSUES
8.1. svn+ssh issues
8.1.1. Message `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
       `svn: E170012: Can't create tunnel`
8.1.2. Message `Can't create session: Unable to connect to a repository at URL 'svn+ssh://...': `
       `To better debug SSH connection problems, remove the -q option from ssh' in the [tunnels] section of your Subversion configuration file. `
       `at .../Git/mingw64/share/perl5/Git/SVN.pm line 310.'`
8.1.3. Message `Keyboard-interactive authentication prompts from server:`
       `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
       `svn: E210002: To better debug SSH connection problems, remove the -q option from 'ssh' in the [tunnels] section of your Subversion configuration file.`
       `svn: E210002: Network connection closed unexpectedly`
8.2. Python execution issues
8.2.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
       `python_tests`
8.2.2. `OSError: [WinError 6] The handle is invalid`
8.3. pytest execution issues
8.4. fcache execution issues
9. AUTHOR EMAIL

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Python-based X-ross Version Control System.

Uses set of scripts with predefined format and parameters to represent the
access to a particular SVN or GIT repository irrespective to the OS.

NOTE:
  The project is experimental and only the Windows is supported.

-------------------------------------------------------------------------------
2. DIRECTORY DEPLOY STRUCTURE
-------------------------------------------------------------------------------
The default directory structure is this:

/<root>
  |
  +-/_pyxvcs
  |  |     - The root scripts directory, represents context for all projects
  |  |       together. Any script execution in that directory has to be
  |  |       applied for all projects represented in subdirectories
  |  |       respectively.
  |  |
  |  +-/<project_group_X1>
  |  |   | - a projects group X, represents context for projects in the group.
  |  |   |   Any script execution in the directory has to be applied for the
  |  |   |   directory and for all projects represented in subdirectories
  |  |   |   respectively.
  |  |   |
  |  |   +-/<project_A1>
  |  |   | - a particular project A, represents a single or a list of
  |  |   |   repositories related to each other in a hierarchy of
  |  |   |   parent-children relation and stored on different remote servers or
  |  |   |   hubs.
  |  |   :
  |  |   :
  |  |   +-/<project_An>
  |  :
  |  :
  |  +-/<project_group_Xn>
  |
  +-/<project_group_X1_WC_roots>
  |   |     - The working copy root directory for a particular project group.
  |   |       Stores working copies in subdirectories for particular projects
  |   |       which has repositories in different remote servers.
  |   |
  |   +-/<project_A1_WC_root_SVN_1>
  |   |     - The working copy directory for the respective SVN #1 remote
  |   |       server.
  |   |
  |   +-/<project_A1_WC_root_GIT_1>
  |   |     - The working copy directory for the respective GIT #1 remote
  |   |        server.
  |   :
  |   :
  |   +-/<project_A1_WC_root_SVN_n>
  |   :
  |   :
  |   +-/<project_A1_WC_root_GIT_n>
  :
  :
  +-/<project_group_Xn_WC_roots>
      |
      :

The particular hierarchy can be deeper as long as it contains at least 3
levels:

* /_pyxvcs
* a project group
* a project

, where a project is always a leaf but project groups can be nested

The directories contains configuration files with various parameters along with
parameters which can be passed to command scripts in these directories.

The system loads configuration files in directories from the root to the most
nested directory.

If a variable in a configuration file from nested directory is intersected with
the same variable in the parent directory, then the value from the nested one
is used instead (variable specialization).

-------------------------------------------------------------------------------
3. FEATURES
-------------------------------------------------------------------------------

Currently only several limited features is suppported:

* one-way limited conversion from svn to git
* svn/git basic commands in a project group context
* one script per a command in a repository

-------------------------------------------------------------------------------
3.1. SVN-to-GIT
-------------------------------------------------------------------------------

Pros:

* access to a remote repository servers only through the svn and git utilities,
  no need a direct access to a bare repository.
* a single SVN repository can be splitted into multiple GIT repositories.
* svn revisions can be represented by the git commits in a not linear history
  (a git commit with more than 1 parent).
* an svn repository subdirectory can be shared in a git repository between
  different git repositories (if have has no recursion), but only one git
  repository can be writable in a project (all not leaf repositories must
  be associated with the same SVN repository, but can be associated with
  different GIT repositories).
  The shared one repository can be not leaf repository only in one project, in
  all other projects it must be a leaf repository because it has to be readonly
  there.
* changes in child git repositories automatically merges altogether into a
  parent git repository to a single commit which becomes a child commit for
  merge into a parent-parent repository and so on
* a checkout of a commit from the root git repository can include content of
  all child git repositories recursively (as a subtree) 
* author name, email and date applies in a `git commit ...` call instead of in
  a `git svn fetch ...` call, so the originally fetched git-svn commits can be
  parents to a local merge commit as is
  (disabled by default, see the flag `--retain_commmit_git_svn_parents`).
* built-in support of `svn+ssh` protocol through the `ssh-pageant` utility.
* all empty directories in an svn repository can be translated into git
  repository(ies) through an empty file
* automatic log of any script in the `pyxvcs` directory through the stdout
  redirection to an external utility.
* a log file contains mostly the calls to the svn and git client utilities and
  can be relatively easy reproduced.

Cons:

* only the SVN trunk is convertible, branches and tags conversion is not
  supported.
* svn externals is not supported and so creation, movement and deletion any
  of them is not detected and not translated into respective git repository.
* svn properties does not automatically convert into git representation
  (`svn:ignore` -> `.gitignore`, `svn:mergeinfo`, etc).
* SVN author translation is supported only for a single author/email per
  GIT repository.
* changes in child git repositories automatically merged in a parent git
  repository only by the value (subtree), by the reference (submodule)
  is not supported.

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------

Currently tested these set of OS platforms, interpreters and modules to run
from:

1. OS platforms.

* Windows 7 (`.bat` only)

2. Interpreters:

* python 3.7.3 or 3.7.5 (3.4+ or 3.5+)
  https://python.org
  - standard implementation to run python scripts
  - 3.7.4 has a bug in the `pytest` module execution, see `KNOWN ISSUES`
    section
  - 3.5+ is required for the direct import by a file path (with any extension)
    as noted in the documentation:
    https://docs.python.org/3/library/importlib.html#importing-a-source-file-directly

3. Modules

* Python site modules:

**  xonsh/0.9.12
    https://github.com/xonsh/xonsh
    - to run python scripts and import python modules with `.xsh` file
      extension
**  plumbum 1.6.7
    https://plumbum.readthedocs.io/en/latest/
    - to run python scripts in a shell like environment
**  win_unicode_console
    - to enable unicode symbols support in the Windows console
**  pyyaml 5.1.1
    - to read yaml format files (.yaml, .yml)
**  conditional 1.3
    - to support conditional `with` statements
**  fcache 0.4.7
    - for local cache storage for python scripts
**  psutil 5.6.7
    - for processes list request
**  tzlocal 2.0.0
    - for local timezone request

Temporary dropped usage:

**  prompt-toolkit 2.0.9
    - optional dependency to the Xonsh on the Windows
**  cmdix 0.2.0
    https://github.com/jaraco/cmdix
    - extension to use Unix core utils within Python environment as plain
      executable or python function

4. Patches:

* Python site modules contains patches in the `python_patches` directory:

** fcache
   - to fix issues from the `fcache execution issues` section.

5. Applications:

* subversion 1.8+
  https://tortoisesvn.net

* git 2.24+
  https://git-scm.com

-------------------------------------------------------------------------------
5. CONFIGURE
-------------------------------------------------------------------------------
1. At first, run the `configure.private.*` script from the root directory.
2. Edit `*.HUB_ABBR` and `*.PROJECT_PATH_LIST` variables to define what and
   where generate respective command scripts.
   Edit the reset of variables for correct account values.
   For example, edit the `GIT.USER`/`GIT.EMAIL`/`GIT2.USER`/`GIT2.EMAIL`
   variables to mirror from svn to git under an unique account
   (will be showed in a merge info after a merge).
3. At second, run the `configure.*` script from the root directory or from a
   subdirectory you are going to use.
4. Edit the `WCROOT_OFFSET` variable in the respective `config.yaml` file
   and change the default working copies directory structure if is required to.

-------------------------------------------------------------------------------
6. USAGE
-------------------------------------------------------------------------------
Any deploy script format:
  `<HubAbbrivatedName>~<ScmName>~<CommandOperation>.*`, where:

  `HubAbbrivatedName` - Hub abbrivated name to run a command for.
  `ScmName`           - Version Source Control service name in a hub.
  `CommandOperation`  - Command operation name to request.

  `HubAbbrivatedName` can be:
    `sf` - SourceForge
    `gl` - GitLab
    `gh` - GitHub
    `bb` - BitBucket

  `ScmName` can be:
    `git` - git source control
    `svn` - svn source control

  `CommandOperation` can be:

  [ScmName=git]
    `init`      - create and initialize local git working copy directory
    `fetch`     - fetch remote git repositories and optionally does
                  (by default is) the pull of all subtrees
    `pull`      - pull remote git repositories and optionally does
                  (by default is) the fetch of all subtrees
    `reset`     - reset local working copy and optionally does
                  (by default is) the reset of all subtree working copies
    `push_svn_to_git` - same as `pull` plus pushes local git working copy
                  to the remote <ScmName> repository
    `compare_commits` - checkouts an svn revision in the SVN WC (as a
                  subdirectory in the `.git` directory of the associated GIT
                  WC) and in the associated GIT WC, and does compares both
                  directories to show changes between SVN and GIT for an SVN
                  revision.
  [ScmName=svn]
    `checkout`  - checks out an svn repository into new svn working copy
                  directory
    `update`    - updates svn working copy directory from the remote svn
                  repository
    `relocate`  - updates svn working copy repository url to the remote svn
                  repository (for example, to change url scheme from
                  `https://` to `svn+ssh://`)

-------------------------------------------------------------------------------
6.1. Mirroring (merging) from SVN to GIT
-------------------------------------------------------------------------------

To take changes from the git REMOTE repository, then these scripts must be
issued:

1. `<HubAbbrivatedName>~git~init.*` (required only if not inited yet)
2. `<HubAbbrivatedName>~git~pull.*`

To do a merge from svn REMOTE repository to git REMOTE repository (through
a LOCAL repository), then these scripts must be issued:

1. `<HubAbbrivatedName>~git~init.*` (required only if not inited yet)
2. `<HubAbbrivatedName>~git~push_svn_to_git.*`

-------------------------------------------------------------------------------
7. SSH+SVN/PLINK SETUP
-------------------------------------------------------------------------------
Based on: https://stackoverflow.com/questions/11345868/how-to-use-git-svn-with-svnssh-url/58641860#58641860

The svn+ssh protocol must be setuped using both the private and the public ssh
key.

In case of in the Windows usage you have to setup the ssh key before run the
svn client using these general steps related to the native Windows `svn.exe`
(should not be a ported one, for example, like the `msys` or `cygwin` tools
which is not fully native):

1. Install the `putty` client.
2. Generate the key using the `puttygen.exe` utility and the correct type of
   the key dependent on the svn hub server (Ed25519, RSA, DSA, etc).
3. Install the been generated public variant of the key into the svn hub server
   by reading the steps from the docs to the server.
4. Ensure that the `SVN_SSH` environment variable in the generated
   `config.env.yaml` file is pointing a correct path to the `plink.exe` and
   uses valid arguments. This would avoid hangs in scripts because of
   interactive login/password request and would avoid usage svn repository
   urls with the user name inside.
5. Ensure that all svn working copies and the `externals` properties in them
   contains valid svn repository urls with the `svn+ssh://` prefix. If not then
   use the `*~svn~relocate.*` scrtip(s) to switch onto it. Then fix all the
   rest urls in the `externals` properties, for example, just by remove the url
   scheme prefix and leave the `//` prefix instead.
6. Run the `pageant.exe` in the background with the previously generated
   private key (add it).
7. Test the connection to the svn hub server through the `putty.exe` client.
   The client should not ask for the password if the `pageant.exe` is up and
   running with has been correctly setuped private key. The client should not
   ask for the user name either if the `SVN_SSH` environment variable is
   declared with the user name.

The `git` client basically is a part of ported `msys` or `cygwin` tools, which
means they behaves a kind of differently.

The one of the issues with the message `Can't create session: Unable to connect
to a repository at URL 'svn+ssh://...': Error in child process: exec of ''
failed: No such file or directory at .../Git/mingw64/share/perl5/Git/SVN.pm
line 310.` is the issue with the `SVN_SSH` environment variable. The variable
should be defined with an utility from the same tools just like the `git`
itself. The attempt to use it with the standalone `plink.exe` from the `putty`
application would end with that message.

So, additionally to the steps for the `svn.exe` application you should apply,
for example, these steps:

1. Drop the usage of the `SVN_SSH` environment variable and remove it.
2. Run the `ssh-pageant` from the `msys` or `cygwin` tools (the `putty`'s
   `pageant` must be already run with the valid private key). You can read
   about it, for example, from here: https://github.com/cuviper/ssh-pageant
   ("ssh-pageant is a tiny tool for Windows that allows you to use SSH keys
   from PuTTY's Pageant in Cygwin and MSYS shell environments.")
3. Create the environment variable returned by the `ssh-pageant` from the
   stdout, for example: `SSH_AUTH_SOCK=/tmp/ssh-hNnaPz/agent.2024`.
4. Use urls in the `git svn ...` commands together with the user name as stated
   in the documentation
   (https://git-scm.com/docs/git-svn#Documentation/git-svn.txt---usernameltusergt ):
   `svn+ssh://<USERNAME>@svn.<url>.com/repo`
   ("For transports that SVN handles authentication for (http, https, and plain
   svn), specify the username. For other transports (e.g. svn+ssh://), you
   **must include the username in the URL**,
   e.g. svn+ssh://foo@svn.bar.com/project")

These instructions should help to use `git svn` commands together with the
`svn` commands.

NOTE:
  The scripts does all above automatically. All you have to do is to ensure
  that you are using valid paths and keys in the respective configuration
  files.

-------------------------------------------------------------------------------
8. KNOWN ISSUES
-------------------------------------------------------------------------------
For the issues around python xonsh module see details in the
`README_EN.python_xonsh.known_issues.txt` file.

-------------------------------------------------------------------------------
8.1. svn+ssh issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
8.1.1. Message `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
       `svn: E170012: Can't create tunnel`
-------------------------------------------------------------------------------

Issue #1:

The `svn ...` command was run w/o properly configured putty plink utility or
w/o the `SVN_SSH` environment variable with the user name parameter.

Solution:

Carefully read the `SSH+SVN/PLINK SETUP` section to fix most of the cases.

Issue #2

The `SVN_SSH` environment variable have has the backslash characters - `\`.

Solution:

Replace all the backslash characters by forward slash character - `/` or by
double baskslash character - `\\`.

-------------------------------------------------------------------------------
8.1.2. Message `Can't create session: Unable to connect to a repository at URL 'svn+ssh://...': `
       `To better debug SSH connection problems, remove the -q option from ssh' in the [tunnels] section of your Subversion configuration file. `
       `at .../Git/mingw64/share/perl5/Git/SVN.pm line 310.'`
-------------------------------------------------------------------------------

Issue:

The `git svn ...` command should not be called with the `SVN_SSH` variable
declared for the `svn ...` command.

Solution:

Read docs about the `ssh-pageant` usage from the msys tools to fix that.

See details: https://stackoverflow.com/questions/31443842/svn-hangs-on-checkout-in-windows/58613014#58613014

NOTE:
  The scripts does automatic maintain of the `ssh-pageant` utility startup.
  All you have to do is to ensure that you are using valid paths and keys in
  the respective configuration files.

-------------------------------------------------------------------------------
8.2. Python execution issues
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
8.2.1. `OSError: [WinError 87] The parameter is incorrect` while try to run
       `python_tests`
-------------------------------------------------------------------------------

Issue:

The `python_tests` scripts fails with the titled message.

Reason:

Python version 3.7.4 is broken on Windows 7:
https://bugs.python.org/issue37549 :
`os.dup() fails for standard streams on Windows 7`

Solution:

Reinstall a different python version.

-------------------------------------------------------------------------------
8.2.2. `OSError: [WinError 6] The handle is invalid`
-------------------------------------------------------------------------------

Issue:

The python interpreter (3.7, 3.8, 3.9) sometimes throws this message at exit,
see details here: https://bugs.python.org/issue37380

Solution:

Reinstall a different python version.

-------------------------------------------------------------------------------
8.1.3. Message `Keyboard-interactive authentication prompts from server:`
       `svn: E170013: Unable to connect to a repository at URL 'svn+ssh://...'`
       `svn: E210002: To better debug SSH connection problems, remove the -q option from 'ssh' in the [tunnels] section of your Subversion configuration file.`
       `svn: E210002: Network connection closed unexpectedly`
-------------------------------------------------------------------------------

Related command: `git svn ...`

Issue #1:

Network is disabled:

Issue #2:

The `pageant` application is not running or the provate SSH key is not added.

Issue #3:

The `ssh-pageant` utility is not running or the `git svn ...` command does run
without the `SSH_AUTH_SOCK` environment variable properly registered.

Solution:

Read the deatils in the `SSH+SVN/PLINK SETUP` section.

-------------------------------------------------------------------------------
8.3. pytest execution issues
-------------------------------------------------------------------------------
* `xonsh incorrectly reorders the test for the pytest` :
  https://github.com/xonsh/xonsh/issues/3380
* `a test silent ignore` :
  https://github.com/pytest-dev/pytest/issues/6113
* `can not order tests by a test directory path` :
  https://github.com/pytest-dev/pytest/issues/6114


-------------------------------------------------------------------------------
8.4. fcache execution issues
-------------------------------------------------------------------------------
* `fcache is not multiprocess aware on Windows` :
  https://github.com/tsroten/fcache/issues/26
* ``_read_from_file` returns `None` instead of (re)raise an exception` :
  https://github.com/tsroten/fcache/issues/27
* `OSError: [WinError 17] The system cannot move the file to a different disk drive.` :
  https://github.com/tsroten/fcache/issues/28

-------------------------------------------------------------------------------
9. AUTHOR EMAIL
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)