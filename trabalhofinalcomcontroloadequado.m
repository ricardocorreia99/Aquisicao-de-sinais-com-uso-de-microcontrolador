
if ~isempty(instrfind)
   fclose(instrfind);
   delete(instrfind);
end
clear all;
close all;
clc

s = serial('COM3','BaudRate',19200); %Selecionar a porta e o baud rate do PIC

fprintf('Pressione o botão S1 para iniciar a conversão\n');
fprintf('Aguarde cerca de 1 segundos para o cálculo do valormédio(calibração)\n'); %O acelerometro deve estar estavel durante o tempo de calibragem
set(s,'FlowControl','none');
set(s,'Parity','none');
set(s,'InputBufferSize',2); %Entram valores 2 a 2(2 bytes de cada vez)
set(s,'OutputBufferSize',1);%Saiem valores 1 a 1(1 byte)
s.InputBufferSize=2;
s.Terminator="";
%flush(s);
s.ReadAsyncMode='continuous';
set(s,'Databits',8);%os dados são de 8 bits
set(s,'StopBit',1);
set(s,'Timeout',10);%Timeout=10s para dar tempo de clicar no botão

fopen(s);%Open it
i=1;
ax=[]; %lista responsável por guardar os  valores da aceleração segundo x de forma a fazer a  média
ay=[]; %lista responsável por guardar os  valores da aceleração segundo y de forma a fazer a  média
az=[]; %lista responsável por guardar os  valores da aceleração segundo z de forma a fazer a  média
% listas onde se vão guardar os valores depois de passar por um filtro de
% média deslizante (smooth)
ax_smoothmed=[];
ay_smoothmed=[];
az_smoothmed=[];

controlo=0;
listaxyz=[];%lista volátil 
count=1;

%Esta parte servirá para o cálculo dos valores de calibragem
%Estes valores  servirão posteriormente para deslocar 
%os gráficos para o 0
%Vai ignorar os valores relacionados com falhas.

while i<400
    
     idn = fscanf(s); %valor recebido
     int=dec2bin(idn); %Valor em binário
     dec=bin2dec(int); %Valor em decimal
     z=(2^8)*(dec(1)) + (dec(2)); %Estabelecimento do peso de cada bit
     acel(i)=z;
     %fprintf('i=%d\n',i);
     %fprintf('valor do acel a entrar:%d\n',acel(i));
     
     if i>=200       %Pontos para o cálculo da média
       if controlo==1 && acel(i)~=65535
           if count==1
               
               listaxyz(end+1)=acel(i); %Primeiro elemento=ax
               count=count+1;
               
           elseif count==2
               listaxyz(end+1)=acel(i); %Segundo elemento=ay
               count=count+1;
               
           elseif count==3
               listaxyz(end+1)=acel(i); %Terceiro elemento=az
               controlo=0; % zerar a variável "controlo"
               
               
               
           end
           
       end
       if acel(i)==65535 && length(listaxyz)==3  %Já tenho listaxyz=[ax,ay,az] e o valor atual é o de controlo? se sim:
           %fprintf('listaxyz=%d\n',listaxyz);
           ax(end+1)=listaxyz(1);      %adicionar o novo ax
           ay(end+1)=listaxyz(2);      %adicionar o novo ay
           az(end+1)=listaxyz(3);
           ax_smoothmed=smooth(ax);
           ay_smoothmed=smooth(ay);
           az_smoothmed=smooth(az);
           
           %adicionar o novo az
           %fprintf('ax=%d\n',ax);
           %fprintf('ay=%d\n',ay);
           %fprintf('az=%d\n',az);
           listaxyz=[];    % esvaziar a lista volátil
           controlo=1;     
           count=1;
           
       elseif acel(i)==65535 && length(listaxyz) ~=3 % o valor atual é o de controlo mas a listaxyz não contem 3 valores? se sim:
           
           listaxyz=[];  % esvaziar a lista volátil
           controlo=1;
           count=1;
           
           
           
       end
     end
     
     
     
  i=i+1;   
end

axmedsmooth=sum(ax_smoothmed)/length(ax_smoothmed); %média do ax depois de passar pelo filtro smooth
aymedsmooth=sum(ay_smoothmed)/length(ay_smoothmed); %média do ay depois de passar pelo filtro smooth
azmedsmooth=sum(az_smoothmed)/length(az_smoothmed); %média do az depois de passar pelo filtro smooth
fprintf('xmedsmooth=%d \n',axmedsmooth);

fprintf('ymedsmooth=%d\n',aymedsmooth);


fprintf('zmedsmooth=%d \n',azmedsmooth);


i=1;
ax_plot=[]; %lista com os valores ax(para fazer o plot com todos os movimentos sem smooth)
ay_plot=[]; %lista com os valores ay(para fazer o plot com todos os movimentos sem smooth)
az_plot=[]; %lista com os valores az(para fazer o plot com todos os movimentos sem smooth)
ax_plotreal=[]; %lista volatil com valores do ax 
ay_plotreal=[]; %lista volatil com valores do ay 
az_plotreal=[]; %lista volatil com valores do az 
controlo=0;
listaxyz=[];% lista volatil(vai ter 3 elementos-ax, ay, az)
count=1;
amostra=0;
listaamostra=[];% lista nao volatil com todas as amostras
amostrareal=[];% vai-nos dizer a amostra correspondente no plot(lista volatil) 

% listas onde se vão guardar os valores depois de passar por um filtro de
% média deslizante (smooth)
ax_smooth=[];
ay_smooth=[];
az_smooth=[];
ax_smoothreal=[];
ay_smoothreal=[];
az_smoothreal=[];

%Servirá para o plot em "tempo real".
%Vai ignorar os valores relacionados com falhas.
%Teremos listas com todos os pontos para no final(caso queiramos) plotar,
%tento com smooth como sem smooth,todo o movimento num só gráfico

while i<=17500 % de forma a fazer refesh do buffer apenas se vai fazer a aquisição de 17500 pontos, se for preciso medir mais algum tempo 
    %então é só executar o programa novamente e executar novos movimentos
    
    idn = fscanf(s);
    int=dec2bin(idn);
    dec=bin2dec(int);
    z=(2^8)*(dec(1)) + (dec(2));
    acel2(i)=z;
    %fprintf('i=%d\n',i);
    %fprintf('valor do acel2 a entrar:%d\n',acel2(i));
    
    if controlo==1 && acel2(i)~=65535
           if count==1
               
               listaxyz(end+1)=acel2(i);
               count=count+1;
               
           elseif count==2
               listaxyz(end+1)=acel2(i);
               count=count+1;
               
           elseif count==3
               listaxyz(end+1)=acel2(i);
               controlo=0;
               
               
               
           end
           
       end
       if acel2(i)==65535 && length(listaxyz)==3
           
           %cada elemento destas lista é descoberto a partir da lista volatil (listaxyz=(ax,ay,az)), da escala e do valor medio do respetivo canal
           ax_plot(end+1)=(1.5*9.8*(listaxyz(1)-axmedsmooth))/((1023-axmedsmooth)); 
           ay_plot(end+1)=(1.5*9.8*(listaxyz(2)-aymedsmooth))/((1023-aymedsmooth));
           az_plot(end+1)=(1.5*9.8*(listaxyz(3)-azmedsmooth))/((1023-azmedsmooth));
           
           % aplcação de um filtro de média deslizante
           ax_smooth=smooth(ax_plot);
           ay_smooth=smooth(ay_plot);
           az_smooth=smooth(az_plot);
           
           amostra=amostra+1;
           listaamostra(end+1)=amostra;% lista com todas as amostras
          
           %Estas listas, embora volateis(vão ser limpas com um certo
           %periodo) vão ser preenchidas com os mesmos valores que as
           %listas anteriores
           ax_plotreal(end+1)=(1.5*9.8*(listaxyz(1)-axmedsmooth))/((1023-axmedsmooth));
           ay_plotreal(end+1)=(1.5*9.8*(listaxyz(2)-aymedsmooth))/((1023-aymedsmooth));
           az_plotreal(end+1)=(1.5*9.8*(listaxyz(3)-azmedsmooth))/((1023-azmedsmooth));
           
            % aplcação de um filtro de média deslizante
           ax_smoothreal=smooth(ax_plotreal);
           ay_smoothreal=smooth(ay_plotreal);
           az_smoothreal=smooth(az_plotreal);
           amostrareal(end+1)=amostra;% Lista volatil com as amostras para o plot de 100 pontos
           if length(ax_smoothreal)==100
               %figure();
               
               %Plot(de 100 pontos) com ax, ay e az em função do numero de amostras 
               plot(amostrareal,ax_smoothreal,'r',amostrareal,ay_smoothreal,'g',amostrareal,az_smoothreal,'m');
               title('Plot em tempo real das acelerações dos 3 eixos');
               xlabel ('numero de amostras')
               ylabel ('aceleração (m/s^2)')
               legend('ax','ay','az')
               ylim([-10 10]); %limites do eixo vertical
               pause(0.0000001); 
               
               %Esvaziar/limpar as listas volateis
               ax_plotreal=[];
               ay_plotreal=[];
               az_plotreal=[];
               ax_smoothreal=[];
               ay_smoothreal=[];
               az_smoothreal=[];
               t_real=[];
               amostrareal=[];
               
           end
           
           listaxyz=[]; %Como já guardamos os valores nas listas anteriores já a podemos limpar, dado que a seguir vai ser preenchida com 3 valores novos
           controlo=1;
           count=1; % Para o proximo valor a ser colocado na listaxyz ser o novo ax
           
           
           
       elseif acel2(i)==65535 && length(listaxyz) ~=3
           % Entramos aqui quando à falha no envio de dados como por
           % exemplo: C ax ay C ax ay az...(perdeu-se um valor de az),
           % sendo capaz de ignorar esses elemntos de forma a não estragar
           % a aquisição
           listaxyz=[];
           controlo=1;
           count=1;
           
           
           
       end
   
    
    
    
    
    
   i=i+1; 
end


fprintf('O tempo de aquisição de dados terminou \n');


fclose(s);

 %title('Plot em tempo real das acelerações dos 3 eixos');
 %xlabel ('numero de amostras')
 %ylabel ('aceleração (m/s^2)')
 %legend('ax','ay','az')
%ylim([-10 10])

% gráfico completo sem smooth
%plot(listaamostra,ax_plot,'r',listaamostra,ay_plot,'g',listaamostra,az_plot,'m')

% gráfico completo com smooth
%plot(listaamostra,ax_smooth,'r',listaamostra,ay_smooth,'g',listaamostra,az_smooth,'m')

%gráfico dos ultimos valores do plot em tempo real
%plot(amostrareal,ax_smoothreal,'r',amostrareal,ay_smoothreal,'g',amostrareal,az_smoothreal,'m');