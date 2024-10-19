#!/bin/bash

# Define cores
GREEN="\033[32m"
RED="\033[31m"
NC="\033[0m" # No Color

# Função para imprimir um banner que permanece na tela
function print_banner {
  clear
  echo -e "${GREEN}"
  echo "============================================="
  echo "         ATUALIZAÇÃO PLW CLUB VIP            "
  echo "============================================="
  echo -e "${NC}"

  # Exibe o banner de ASCII Art
  printf "${GREEN}"  
  printf "██████╗░██╗░░░░░░██╗░░░░░░░██╗\n";
  printf "██╔══██╗██║░░░░░░██║░░██╗░░██║\n";
  printf "██████╔╝██║░░░░░░╚██╗████╗██╔╝\n";
  printf "██╔═══╝░██║░░░░░░░████╔═████║░\n";
  printf "██║░░░░░███████╗░░╚██╔╝░╚██╔╝░\n";
  printf "╚═╝░░░░░╚══════╝░░░╚═╝░░░╚═╝░░\n";
  printf "${NC}"
}

# Função para criar o sufixo incrementado
function get_incremented_folder_name {
  base_name="$1-old"
  increment=1
  new_folder_name="$base_name"

  while [ -d "$new_folder_name" ]; do
    new_folder_name="${base_name}-${increment}"
    increment=$((increment + 1))
  done

  echo "$new_folder_name"
}

# Exibe o banner
print_banner

# Exibe o aviso importante
echo -e "${GREEN}AVISO IMPORTANTE: Antes de prosseguir, faça um backup e snapshot da sua máquina (VPS).${NC}"
read -p "Deseja continuar? [Y/N]: " choice

if [[ "$choice" != "Y" && "$choice" != "y" ]]; then
  echo -e "${GREEN}Operação cancelada. Por favor, faça um backup antes de prosseguir.${NC}"
  exit 1
fi

# Exibe o banner novamente após a confirmação
print_banner

# Parando todas as tarefas do PM2
echo -e "${GREEN}Parando todas as tarefas do PM2...${NC}"
sudo su deploy -c "pm2 stop all"
sudo su deploy -c "exit"

# Exibe o banner novamente
print_banner

# Solicitando o caminho do diretório de deploy
echo -e "${GREEN}Digite o caminho do diretório de deploy (ex: /home/deploy):${NC}"
read deploy_path

if [ ! -d "$deploy_path" ]; then
  echo -e "${RED}Caminho $deploy_path não existe. Operação cancelada.${NC}"
  exit 1
fi

cd "$deploy_path" || { echo -e "${RED}Falha ao acessar o caminho $deploy_path. Operação cancelada.${NC}"; exit 1; }

# Exibe o banner novamente
print_banner

# Solicitando o nome da pasta a ser renomeada
echo -e "${GREEN}Digite o nome da pasta que deseja renomear:${NC}"
read old_folder_name

if [ ! -d "$old_folder_name" ]; then
  echo -e "${RED}A pasta $old_folder_name não existe. Operação cancelada.${NC}"
  exit 1
fi

# Exibe o banner novamente
print_banner

# Determinando o nome da nova pasta (incrementando se necessário)
new_old_folder_name=$(get_incremented_folder_name "$old_folder_name")
mv "$old_folder_name" "$new_old_folder_name"

# Solicitando o novo nome para a pasta
echo -e "${GREEN}Digite o novo nome para a pasta:${NC}"
read new_folder_name

# Definindo o usuário do GitHub e solicitando a senha
github_user="plwdesign"  # Substitua pelo seu nome de usuário GitHub
echo -e "${GREEN}Digite a senha do GitHub para o usuário ${github_user} (a senha ficará invisível):${NC}"
read -s github_password

# Clonando o repositório com autenticação básica
git clone https://${github_user}:${github_password}@github.com/plwdesign/vipclub.git "$new_folder_name"

# Exibe o banner novamente
print_banner

# Copiando arquivos .env e server.js
cp "$new_old_folder_name/backend/.env" "$new_folder_name/backend/.env"
cp "$new_old_folder_name/frontend/.env" "$new_folder_name/frontend/.env"
cp "$new_old_folder_name/frontend/server.js" "$new_folder_name/frontend/server.js"

# Exibe o banner novamente
print_banner

# Executando comandos no backend
echo -e "${GREEN}Rodando comandos no backend...${NC}"
cd "$deploy_path/$new_folder_name/backend" || { echo -e "${RED}Falha ao acessar o diretório do backend. Operação cancelada.${NC}"; exit 1; }
npm install
npm run build
npx sequelize db:migrate

# Exibe o banner novamente
print_banner

# Executando comandos no frontend
echo -e "${GREEN}Rodando comandos no frontend...${NC}"
cd "$deploy_path/$new_folder_name/frontend" || { echo -e "${RED}Falha ao acessar o diretório do frontend. Operação cancelada.${NC}"; exit 1; }
npm install
npm run build

# Exibe o banner novamente
print_banner

# Editando package.json no frontend
echo -e "${GREEN}Abrindo o package.json no frontend para editar...${NC}"
nano "$deploy_path/$new_folder_name/frontend/package.json"

# Exibe o banner novamente
print_banner

# Editando index.html no frontend/public
echo -e "${GREEN}Abrindo o index.html no frontend/public para editar...${NC}"
nano "$deploy_path/$new_folder_name/frontend/public/index.html"

# Exibe o banner novamente
print_banner

# Rodando novamente npm install e npm run build no frontend
echo -e "${GREEN}Rodando npm install e npm run build novamente no frontend...${NC}"
npm install
npm run build

# Exibe o banner novamente
print_banner

# Reiniciando o PM2
echo -e "${GREEN}Reiniciando o PM2...${NC}"
sudo su deploy -c "pm2 restart all"

# Exibe o banner novamente
print_banner

# Instrução para mover a pasta public
echo -e "${RED}Mova a pasta 'public' para o novo diretório, se necessário.${NC}"

# Exibe o banner novamente
print_banner

echo -e "${GREEN}Script finalizado. Se aconteceu algum erro nos chame no suporte!${NC}"
echo -e "${GREEN}
npm install (No backend)
npm run build (No backend)
npx sequelize db:migrate (No backend)

npm install (No frontend)
npm run build (No frontend)

sudo su deploy
pm2 restart all
${NC}"

# Informações de contato
echo -e "${GREEN}Sites e Contatos:${NC}"
echo -e "${GREEN}Site: www.plwdesign.online${NC}"
echo -e "${GREEN}Site: vip.plwdesign.online${NC}"
echo -e "${GREEN}Suporte pelo site!${NC}"

