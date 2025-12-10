addpath('Metodos_Auxiliares');
% ler gabaritos da pasta Gabaritos

% -- Alternativamente, dá pra ler os gabaritos das folhas geradas à partir do gera_folha_resposta_e_gabarito.m
% tipos = 'ABCD';
% for i = 1:4
%     arquivo = sprintf('Gabaritos/gabarito_%c.png', tipos(i));
%     gabaritos(i) = ler_folha_resposta_simples(arquivo, true);
% end
% os valores são os mesmos: gabaritos.mat

load("gabaritos.mat")

% LER FRs DA PASTA Folhas_Respostas 
for i = 1:5
    arquivo = sprintf('Folhas_Resposta/FR%d.png', i);
    respostas(i) = ler_folha_resposta_por_foto(arquivo, true);
end

% MOSTRAR RESULTADOS
for i = 1:5
    if respostas(i).tipoProva ~= ""
        fprintf('Prova FR%d acertou %d questões da prova %c \n', i, sum(gabaritos.(respostas(i).tipoProva) == respostas(i).respostas), respostas(i).tipoProva);
    else
        fprintf('Prova FR%d não leu corretamente, tente novamente com menos distorções\n', i);
    end
end


