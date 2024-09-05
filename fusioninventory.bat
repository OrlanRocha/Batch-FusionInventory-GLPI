@echo off
REM BATCH PARA INSTALAÇÃO DO FusionInventory
REM FEITO POR ORLAN ROCHA
REM GITHUB = https://github.com/Luis-Orlan

set versao=2.6
set ip_server=127.0.0.1
set caminhoGLPI=glpi/plugins/fusioninventory
set tarefas=Full

set setup_Options=/S /acceptlicense /runnow /installtasks=%tarefas% /httpd-trust='127.0.0.1/32,%ip_server%' /scan-homedirs /scan-profiles /server='http://%ip_server%/%caminhoGLPI%/'

echo FusionInventory-Agent: Iniciando
echo FusionInventory-Agent: Hostname %computername%

REM DESABILITA Windows FIREWALL (OPCIONAL)
echo FusionInventory-Agent: Ajustando Windows Firewall 
netsh advfirewall set allprofiles state off>nul 2>&1
netsh advfirewall set domainprofile state off>nul 2>&1
netsh advfirewall set privateprofile state off>nul 2>&1
netsh advfirewall set publicprofile state off>nul 2>&1

echo FusionInventory-Agent: Ajustando servico RDP>nul 2>&1

REM HABILITA RDP NO COMPUTADOR (OPCIONAL)
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes>nul 2>&1
sc config RemoteRegistry start=auto>nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f>nul 2>&1
net stop remoteregistry>nul 2>&1
net start remoteregistry>nul 2>&1

REM VERIFICA SE O SERVIÇO ESTA RODANDO
sc query "FusionInventory-Agent" | find /C /I "RUNNING">nul
if %errorlevel%==0 (
	echo FusionInventory-Agent: Serviço já está rodando
	set instalar=nao
) else (
	echo FusionInventory-Agent: Serviço não está rodando
	set instalar=sim
)

REM VALIDA ARQUITETURA DO SISTEMA
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	set arq_system=x64
) else (
	set arq_system=x86
)

REM DEFINE CAMINHO DO AGENTE
set downloadAgente=http://%ip_server%/%caminhoGLPI%/agent/fusioninventory-agent_windows-%arq_system%_%versao%.exe

REM VALIDA SE O AGENTE DEVE SER INSTALADO
if %instalar%==sim (
	echo FusionInventory-Agent: Será necessário instalar o FusionInventory %arq_system%
	goto :baixarAgente
) else (
	echo FusionInventory-Agent: O FusionInventory %arq_system% já está instalado
	goto :sair
)

:baixarAgente
echo FusionInventory-Agent: Servidor %ip_server%

REM DESINSTALA O AGENTE CASO EXISTA 
if exist "%ProgramFiles%\FusionInventory-Agent" (
	cd "%ProgramFiles%\FusionInventory-Agent"
	call Uninstall.exe /S
)

if exist "%ProgramFiles(x86)%\FusionInventory-Agent" (
	cd "%ProgramFiles(x86)%\FusionInventory-Agent"
	call Uninstall.exe /S
)

REM FAZ O DOWNLOAD DO AGENTE
echo FusionInventory-Agent: Efetuando download do agente
bitsadmin /RESET /ALLUSERS>nul 2>&1
bitsadmin /transfer FusionInventory /download /priority normal %downloadAgente% "%ProgramData%\fusioninventory-agent_windows-%arq_system%_%versao%.exe">nul 2>&1

if not exist "%ProgramData%\fusioninventory-agent_windows-%arq_system%_%versao%.exe" (
	echo FusionInventory-Agent: Falha no download do agente
	goto :sair
)

REM INSTALAÇÃO DO AGENTE
echo FusionInventory-Agent: Iniciando instalação
cd C:\ProgramData\
call fusioninventory-agent_windows-%arq_system%_%versao%.exe %setup_Options%

echo FusionInventory-Agent: Aguardando 30 segundos para conclusão da instalação
timeout /t 30 >nul

REM INICIA SERVIÇO CASO NAO TENHA INICIADO
sc config FusionInventory-Agent start=delayed-auto>nul 2>&1
sc failure FusionInventory-Agent actions=restart/60000/restart/60000/restart/60000 reset=3600000>nul 2>&1
net start FusionInventory-Agent>nul 2>&1

REM VERIFICA O STATUS DO AGENTE
curl -s http://localhost:62354/status | find "status:"

echo FusionInventory-Agent: FIM
goto :sair

:sair
exit