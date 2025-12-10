function gera_folha_resposta_e_gabarito(tipoProva, gabarito, nomeArquivoSaida)

    % CONFIGURAÇÕES
    W = 2480; H = 3508; % tamanho página A4
    raioBolha = 25; % raio da bolha vermelha
    raioPreench = floor(raioBolha*0.90); % círculo preto interno
    baseX = [350 1350]; % colunas de questões
    baseY = 600; % início da tabela (coordenada vertical)
    deltaY = 60; % espaçamento vertical entre linhas (questões)
    deltaXAlt = 100; % espaçamento horizontal entre as alternativas A, B, C, D, E na mesma linha
    letrasAlt = {'A','B','C','D','E'}; % questões
    letrasProva = {'A','B','C','D'}; % tipo dr prova
    centrosProvaX = 350 + (0:4)*180; % posição horizontal das bolhas do tipo de prova
    cyProva = 400; % cordenada vertical onde ficam as bolhas do tipo de prova
    headerOffsetY = 50;

    % cria página branca 
    img = uint8(255 * ones(H, W, 3));

    % marcadores pretos nos 4 cantos
    img = desenharMarcadoresCantos(img);

    % cabeçalho 
    img = desenharCabecalho(img);

    % tipo de prova 
    img = desenharBolinhasTipoProva(img, centrosProvaX, cyProva, letrasProva, raioBolha);

    % preencher bolha do tipo correto 
    if tipoProva == 'X'
        idx = find('ABCDE' == tipoProva);
        if ~isempty(idx)
            img = preencherCirculo(img, centrosProvaX(idx), cyProva, raioPreench);
        end
    end

    % questões + alternativas 
    img = desenharQuestoes(img, baseX, baseY, deltaY, deltaXAlt, letrasAlt, raioBolha, headerOffsetY);

    % preencher respostas do gabarito
    if gabarito == 'X'

        nQuestoes = numel(gabarito);
        for q = 1:nQuestoes
            alt = gabarito(q);
            if alt < 1 || alt > 5, continue; end
    
            col = (q > 25) + 1;
            linha = mod(q-1, 25) + 1;
            y = baseY + (linha-1)*deltaY;
            cx = baseX(col) + (alt-1)*deltaXAlt;
    
            img = preencherCirculo(img, cx, y, raioPreench);
        end
    
        % salvar imagem 
        imwrite(img, nomeArquivoSaida);

    end

end


% FUNÇÕES AUXILIARES
function img = desenharCabecalho(img)
    img = insertText(img, [250 150], 'PROVA', ...
        'FontSize', 40, 'BoxOpacity', 0, 'TextColor', 'black');
    img = insertText(img, [250 220], ...
        'Preencha completamente a bolha da alternativa escolhida.', ...
        'FontSize', 26, 'BoxOpacity', 0, 'TextColor', 'black');
    img = insertText(img, [250 270], 'Tipo de prova:', ...
        'FontSize', 32, 'BoxOpacity', 0, 'TextColor', 'black');
end


function img = desenharBolinhasTipoProva(img, centrosX, cy, letras, raio)
    for k = 1:numel(letras)
        img = insertText(img, [centrosX(k), cy - raio - 30], letras{k}, ...
            'FontSize', 28, 'AnchorPoint','Center','BoxOpacity',0,'TextColor','black');
        img = insertShape(img, 'Circle', [centrosX(k) cy raio], ...
            'Color','red','LineWidth',3);
    end
end


function img = desenharQuestoes(img, baseX, baseY, deltaY, deltaXAlt, letras, raio, headerOffsetY)
    % cabeçalho A B C D E
    for col = 1:2
        for alt = 1:5
            cx = baseX(col) + (alt-1)*deltaXAlt;
            img = insertText(img, [cx, baseY - headerOffsetY], letras{alt}, ...
                'FontSize', 24, 'AnchorPoint','Center','BoxOpacity',0,'TextColor','black');
        end
    end

    % questões
    for q = 1:50
        col   = (q > 25) + 1;
        linha = mod(q-1, 25) + 1;
        y = baseY + (linha-1)*deltaY;

        img = insertText(img, [baseX(col)-90 y], sprintf('%02d', q), ...
            'FontSize', 22, 'AnchorPoint','Center','BoxOpacity',0,'TextColor','black');

        % bolhas
        for alt = 1:5
            cx = baseX(col) + (alt-1)*deltaXAlt;
            img = insertShape(img, 'Circle', [cx y raio], ...
                'Color','red','LineWidth',3);
        end
    end
end


function img = preencherCirculo(img, cx, cy, r)

    [xGrid, yGrid] = meshgrid(-r:r, -r:r);
    mask = (xGrid.^2 + yGrid.^2) <= r^2;
    [h,w] = size(mask);

    x1 = round(cx - w/2); y1 = round(cy - h/2);
    x2 = x1+w-1;          y2 = y1+h-1;

    if x1 < 1 || y1 < 1 || x2 > size(img,2) || y2 > size(img,1), return; end

    for c = 1:3
        region = img(y1:y2, x1:x2, c);
        region(mask) = 0;
        img(y1:y2, x1:x2, c) = region;
    end
end

function img = desenharMarcadoresCantos(img)
    % desenha 4 quadrados pretos nos cantos da folha
    [H, W, ~] = size(img);

    margem = 120; % distância da borda
    tamQuad = 80; % lado do quadrado em pixels

    % canto esquerdo superior
    x1 = margem;
    y1 = margem;
    img(y1:y1+tamQuad-1, x1:x1+tamQuad-1, :) = 0;

    % canto direito superior
    x2 = W - margem - tamQuad + 1;
    y2 = margem;
    img(y2:y2+tamQuad-1, x2:x2+tamQuad-1, :) = 0;

    % canto inferior esquerdo
    x3 = margem;
    y3 = H - margem - tamQuad + 1;
    img(y3:y3+tamQuad-1, x3:x3+tamQuad-1, :) = 0;

    % canto inferior direito
    x4 = W - margem - tamQuad + 1;
    y4 = H - margem - tamQuad + 1;
    img(y4:y4+tamQuad-1, x4:x4+tamQuad-1, :) = 0;
end
