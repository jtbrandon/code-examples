# env.py will disable/reenable an environment from deploying projects 

The process for this script is that it will modify the environments of a team (for now NVO developers)
It will remove/add envs to disable and enable, respectively.
It will also keep all the env's in a particular order


To run this script run: **Python env.py {-d for Disable, -e for Enable} {env} {env}...{env}**

Example: python env.py disable ext6 env20 
