function resultado = ler_folha_resposta_retificada(nomeImagem, debugPlot)

    if nargin < 2
        debugPlot = true;
    end

    % CONSTANTES DO LAYOUT ORIGINAL (usado na geração)
    larguraOriginal = 2480;
    alturaOriginal = 3508;
    raioOriginal = 25;

    baseX_orig = [350 1350]; % colunas esquerda/direita
    baseY_orig = 600; % primeira linha de questão
    deltaY_orig = 60; % espaço vertical entre as questões
    deltaXAlt_orig = 100; % espaço horizontal entre as alternativas
    centrosProvaX_orig = 350 + (0:4)*180;
    cyProva_orig = 400;
    yMinQuestoes_orig = baseY_orig - 30; % limite para separar prova/questões

    letrasProva = 'ABCD';

    % LER IMAGEM E 'PREPARAR'
    if ischar(nomeImagem) || isstring(nomeImagem)
        I = imread(nomeImagem);
    else
        I = nomeImagem; % já é matriz de imagem
    end

    if size(I,3) == 3
        G = rgb2gray(I);
    else
        G = I;
    end

    G = mat2gray(G);
    G = medfilt2(G, [3 3]);
    G = imadjust(G);

    [H, W] = size(G);

    % ESCALONAR LAYOUT PARA TAMANHO DA FOTO
    escalaY = H / alturaOriginal;
    escalaX = W / larguraOriginal;
    escala = (escalaX + escalaY)/2; % assumindo pouca distorção, dá pra usar a média:

    raioEstimado = raioOriginal * escala;
    baseX = baseX_orig * escalaX;
    baseY = baseY_orig * escalaY;
    deltaY = deltaY_orig * escalaY;
    deltaXAlt = deltaXAlt_orig * escalaX;
    centrosProvaX = centrosProvaX_orig * escalaX;
    cyProva = cyProva_orig * escalaY;
    yMinQuestoes = yMinQuestoes_orig * escalaY;

    % DETECTAR TODOS OS CÍRCULOS (bolhas + 'lixo')
    rMin = max(5, round(0.85 * raioEstimado));
    rMax = round(1.15 * raioEstimado);

    [centers, radii] = imfindcircles(G, [rMin rMax], 'ObjectPolarity','dark', 'Sensitivity', 0.95, 'EdgeThreshold', 0.1);

    if isempty(centers)
        warning('Nenhum círculo detectado.');
        resultado = struct('tipoProva','', 'respostas',zeros(1,50), 'centersFilled',[], 'radiiFilled',[]);
        return;
    end

    % FILTRAR REGIÃO VÁLIDA (ignorar texto no topo)
    yMinValido = 320 * escalaY; % tudo acima disso é texto/cabeçalho
    maskRegiao = centers(:,2) >= yMinValido;
    centers = centers(maskRegiao,:);
    radii = radii(maskRegiao);

    if isempty(centers)
        warning('Nenhum círculo na região válida.');
        resultado = struct('tipoProva','', 'respostas',zeros(1,50), 'centersFilled',[], 'radiiFilled',[]);
        return;
    end

    % CLASSIFICAR 'PREENCHIDO' e 'VAZIO'
    nCirc = size(centers,1);
    isFilled = false(nCirc,1);

    fatorInterno = 0.45; % só o centro da bolha

    for i = 1:nCirc
        cx = centers(i,1);
        cy = centers(i,2);
        rInt = radii(i) * fatorInterno;

        % máscara circular interna
        [xGrid, yGrid] = meshgrid(-rInt:rInt, -rInt:rInt);
        maskCirc = (xGrid.^2 + yGrid.^2) <= rInt^2;
        [hMask,wMask] = size(maskCirc);

        % recorte do centro da bolha
        x1 = round(cx - wMask/2);
        y1 = round(cy - hMask/2);
        x2 = x1 + wMask - 1;
        y2 = y1 + hMask - 1;

        if x1 < 1 || y1 < 1 || x2 > W || y2 > H
            continue;
        end

        recorte = G(y1:y2, x1:x2);
        intensidadeBolha = mean(recorte(maskCirc));  % 0 preto, 1 branco

        % região maior ao redor (para média local, combate sombra)
        raioJanela = round(3 * rInt);
        x1L = max(1, round(cx - raioJanela));
        y1L = max(1, round(cy - raioJanela));
        x2L = min(W, round(cx + raioJanela));
        y2L = min(H, round(cy + raioJanela));

        janelaLocal = G(y1L:y2L, x1L:x2L);
        mediaLocal = mean(janelaLocal(:));

        % limiar adaptativo: bolha deve ser significativamente mais escura que o entorno
        limiarAdapt = mediaLocal - 0.18; % ajuste fino (0.15–0.25)
        limiarAdapt = max(limiarAdapt, 0.15); % evita valor muito baixo

        isFilled(i) = intensidadeBolha < limiarAdapt;
    end

    centersFilled = centers(isFilled,:);
    radiiFilled = radii(isFilled);

    % IDENTIFICAR TIPO DE PROVA 
    tipoProva = '';
    if ~isempty(centersFilled)
        % escolhe bolhas preenchidas próximas à linha do tipo de prova
        tolYProva = deltaY * 0.8;  % tolerância vertical
        idxCandProva = abs(centersFilled(:,2) - cyProva) <= tolYProva;

        centersProvaFilled = centersFilled(idxCandProva,:);

        if ~isempty(centersProvaFilled)
            % para cada candidata, encontra o centro de prova mais próximo

            numMarks = size(centersProvaFilled,1);
            idxCols = zeros(numMarks,1);
            
            for k = 1:numMarks
                [~, idxCols(k)] = min( abs(centersProvaFilled(k,1) - centrosProvaX) );
            end
            
            % pega a primeira (assumindo 1 bolha de prova marcada)
            idxTipo = idxCols(1);
            tipoProva = letrasProva(idxTipo);
        end
    end

    % IDENTIFICAR AS RESPOSTAS DAS QUESTÕES
    respostas = zeros(1,50);

    if ~isempty(centersFilled)
        % bolhas preenchidas abaixo da faixa do tipo de prova -> questões
        idxCandQuestoes = centersFilled(:,2) >= yMinQuestoes;
        centersQuest = centersFilled(idxCandQuestoes,:);

        for i = 1:size(centersQuest,1)
            cx = centersQuest(i,1);
            cy = centersQuest(i,2);

            % qual coluna (1 ou 2)? divide pela metade da largura ou usa referência das colunas baseX
            if abs(cx - baseX(1)) < abs(cx - baseX(2))
                col = 1;
            else
                col = 2;
            end

            % linha aproximada (1 a 25)
            linha = round((cy - baseY)/deltaY) + 1;

            % alternativa (1 a 5)
            alt = round((cx - baseX(col))/deltaXAlt) + 1;

            % calcula número da questão global (1 a 50)
            q = (col-1)*25 + linha;

            % valida ranges
            if linha < 1 || linha > 25 || alt < 1 || alt > 5 || q < 1 || q > 50
                continue;
            end

            % se já houver uma marca para essa questão, pode sobrescrever ou marcar como 0 (anulada), no caso vou só sobrescrever (assumindo 1 marcação)
            respostas(q) = alt;
        end
    end

    % DEBUG PLOT 
    if debugPlot
        figure;
        imshow(I); hold on;

        % desenha todas bolhas detectadas (verde)
        viscircles(centers, radii, 'EdgeColor','g');

        % bolhas preenchidas (vermelho)
        viscircles(centersFilled, radiiFilled, 'EdgeColor','r');

        title(sprintf('Tipo: %s, bolhas preenchidas: %d', tipoProva, size(centersFilled,1)));

        hold off;
    end

    % MONTAR SAÍDA
    resultado.tipoProva = tipoProva;
    resultado.respostas = respostas;
    resultado.centersFilled = centersFilled;
    resultado.radiiFilled = radiiFilled;
end
