# FusionInventory Agent Installer

Este repositório contém um script de **batch** para automatizar a instalação do **FusionInventory Agent** em máquinas Windows. O script desativa o firewall do Windows (opcional), ajusta o serviço de Área de Trabalho Remota (RDP), valida a arquitetura do sistema, verifica se o serviço do FusionInventory Agent já está rodando, realiza a instalação do agente caso necessário e configura o serviço para iniciar automaticamente com o sistema.

## Funcionalidades

- Desabilita o Firewall do Windows (opcional).
- Configura o serviço de Área de Trabalho Remota (RDP).
- Valida se o **FusionInventory Agent** já está instalado.
- Baixa e instala a versão correta do agente conforme a arquitetura do sistema (x86 ou x64).
- Reinicia o serviço do agente e força o inventário após a instalação.
- Configura o serviço do agente para iniciar automaticamente com atraso e para reiniciar em caso de falhas.

## Pré-requisitos

- A máquina deve ter acesso ao servidor FusionInventory configurado no script (atualmente setado como `127.0.0.1`).
- Ferramentas como `bitsadmin` e `curl` devem estar disponíveis no sistema operacional.
- Acesso de administrador para modificar as configurações de firewall e serviços.

## Como usar

1. **Clone o repositório**:

   ```bash
   git clone https://github.com/Luis-Orlan/fusioninventory-agent-installer.git
   cd fusioninventory-agent-installer
