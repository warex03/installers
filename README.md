# Installers
> This contains the various installers that I personally use

## Manjaro

- Run the following commands:

```bash
sudo pacman -Sy ansible
cd manjaro
ansible-playbook -i hosts main.yml --extra-vars "ansible_become_pass=yourPassword"
```
