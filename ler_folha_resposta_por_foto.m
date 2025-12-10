function resultado = ler_folha_resposta_por_foto(nomeImagem, debugPlot)
addpath('Metodos_Auxiliares');
% lê foto, detecta os 4 marcadores dos cantos, aplica transformação
% projetiva pro tamanho original (2480x3508), e então utiliza
% ler_folha_respostas na imagem corrigida
    if nargin < 2
        debugPlot = true;
    end

    % LER FOTO
    Iorig = imread(nomeImagem);
    if size(Iorig,3) == 3
        G = rgb2gray(Iorig);
    else
        G = Iorig;
    end

    G = mat2gray(G);

    [Hf, Wf] = size(G);

    % ESTIMAR ESCALA PARA TAMANHO DOS MARCADORES
    % tamanho original da folha e do quadrado:
    larguraOrig = 2480;
    alturaOrig = 3508;
    ladoQuadOrig = 80; % mesmo da gera_folha_resposta

    escalaY = Hf / alturaOrig;
    escalaX = Wf / larguraOrig;
    escala = (escalaX + escalaY) / 2;

    ladoQuadEst = ladoQuadOrig * escala;

    areaMin = (ladoQuadEst * 0.5)^2; % elevado ao quadrado porque os marc são detectados como área
    areaMax = (ladoQuadEst * 2.0)^2;

    % BINARIZAR E ACHAR COMPONENTES PRETOS GRANDES
    T = graythresh(G); % limiar de Otsu (0..1)
    BW = G < T * 0.7; % pega regiões mais escuras

    BW = bwareaopen(BW, round(areaMin/2));  % remove pequenos ruídos

    stats = regionprops(BW, 'Area', 'BoundingBox', 'Centroid');

    candidatos = [];
    for i = 1:numel(stats)
        A = stats(i).Area;
        if A < areaMin || A > areaMax
            continue;
        end
        bb = stats(i).BoundingBox;
        w  = bb(3); h = bb(4);
        aspecto = w/h;
        if aspecto < 0.7 || aspecto > 1.3
            continue;  % não é quase quadrado
        end

        candidatos = [candidatos; stats(i).Centroid, A]; %#ok<AGROW>
    end

    if size(candidatos,1) < 4
        warning('Não foram encontrados 4 marcadores de canto. Encontrados: %d', size(candidatos,1));
    end

    % Pega os 4 maiores por área
    if isempty(candidatos)
        error('Nenhum marcador de canto detectado.');
    end

    % ordenar por área desc e pegar até 4
    [~, idxOrd] = sort(candidatos(:,3), 'descend');
    idxUse = idxOrd(1:min(4,numel(idxOrd)));
    pontos = candidatos(idxUse,1:2); % [x y]

    if size(pontos,1) < 4
        error('Menos de 4 marcadores válidos encontrados.');
    end

    % ORDENAR PONTOS: TL, TR, BR, BL
    % ordena por Y (topo -> baixo)
    [~, idxY] = sort(pontos(:,2));
    top2 = pontos(idxY(1:2),:);
    bottom2 = pontos(idxY(3:4),:);

    % dentro dos top2, menor X = TL, maior X = TR
    [~, idxTopX] = sort(top2(:,1));
    TL = top2(idxTopX(1),:);
    TR = top2(idxTopX(2),:);

    % dentro dos bottom2, menor X = BL, maior X = BR
    [~, idxBotX] = sort(bottom2(:,1));
    BL = bottom2(idxBotX(1),:);
    BR = bottom2(idxBotX(2),:);

    movingPoints = [TL; TR; BR; BL]; % na imagem da foto


    % PONTOS DE DESTINO: CENTROS DOS QUADRADOS NA FOLHA ORIGINAL 
    W0 = larguraOrig;
    H0 = alturaOrig;

    margem = 120; % mesmo de desenharMarcadoresCantos
    tamQuad = ladoQuadOrig; % 80

    % centros dos marcadores na folha gerada
    dst_TL = [margem + tamQuad/2, margem + tamQuad/2];
    dst_TR = [W0 - margem - tamQuad/2, margem + tamQuad/2];
    dst_BL = [margem + tamQuad/2, H0 - margem - tamQuad/2];
    dst_BR = [W0 - margem - tamQuad/2, H0 - margem - tamQuad/2];

    fixedPoints = [dst_TL; dst_TR; dst_BR; dst_BL];

    % AJUSTAR TRANSFORMAÇÃO PROJETIVA E RETIFICAR 
    tform = fitgeotrans(movingPoints, fixedPoints, 'projective');

    outputRef = imref2d([H0 W0]); % quero exatamente 3508x2480
    Icorrigida = imwarp(Iorig, tform, 'OutputView', outputRef);

    % DEBUG
    if debugPlot
        figure;
        subplot(1,2,1);
        imshow(Iorig); hold on;
        plot(movingPoints(:,1), movingPoints(:,2), 'ro', 'MarkerSize', 10, 'LineWidth',2);
        title('Foto original com marcadores detectados');

        subplot(1,2,2);
        imshow(Icorrigida);
        title('Folha retificada (2480 x 3508)');
    end

    % RODAR ler_folha_respostas NA IMAGEM RETIFICADA
    resultado = ler_folha_resposta_retificada(Icorrigida, debugPlot);
end
