function [nPreenchidos, centersFilled, radiiFilled] = conta_circulos_preenchidos(nomeImagem, debugPlot)

    if nargin < 2
        debugPlot = true;
    end

    % LER IMAGEM E 'PREPARAR'
    I = imread(nomeImagem);

    if size(I,3) == 3
        G = rgb2gray(I);
    else
        G = I;
    end

    G = mat2gray(G);
    G = medfilt2(G, [3 3]);
    G = imadjust(G);

    [H, W] = size(G);

    % ESTIMAR FAIXA DE RAIOS DAS BOLHAS
    alturaOriginal = 3508; % folha gerada
    raioOriginal = 25; % raio bolha na geração

    escala = H / alturaOriginal;
    raioEstimado = raioOriginal * escala;

    % faixa bem apertada em torno do raio estimado
    rMin = max(5, round(0.85 * raioEstimado));
    rMax = round(1.15 * raioEstimado);

    % DETECTAR TODOS OS CÍRCULOS (BOLHAS + 'LIXO')
    [centers, radii] = imfindcircles(G, [rMin rMax], 'ObjectPolarity','dark', 'Sensitivity', 0.95, 'EdgeThreshold', 0.1);

    nTotal = size(centers,1);
    fprintf('Total de círculos (após filtro de raio): %d\n', nTotal);

    if nTotal == 0
        nPreenchidos = 0; centersFilled = []; radiiFilled = [];
        return;
    end

    % FILTRO DE REGIÃO: ignora topo (texto), nas folhas geradas, as bolhas começam ~y=400 (tipo prova) e as questões em ~y=600. Vamos ignorar tudo com y < 320.
    yMinValido = 320;
    regioesValidas = centers(:,2) >= yMinValido;

    centers = centers(regioesValidas,:);
    radii = radii(regioesValidas);
    nTotal = size(centers,1);

    fprintf('Após filtro de região (y >= %d): %d círculos.\n', yMinValido, nTotal);

    if nTotal == 0
        nPreenchidos = 0; centersFilled = []; radiiFilled = [];
        return;
    end

    % CLASSIFICAR ENTRE PREENCHIDO E VAZIO 
    fatorInterno = 0.6; % fração do raio para medir interior
    intensidades = zeros(nTotal,1);

    for i = 1:nTotal
        cx = centers(i,1);
        cy = centers(i,2);
        r = radii(i) * fatorInterno;

        [xGrid, yGrid] = meshgrid(-r:r, -r:r);
        mask = (xGrid.^2 + yGrid.^2) <= r^2;

        [hMask, wMask] = size(mask);
        x1 = round(cx - wMask/2);
        y1 = round(cy - hMask/2);
        x2 = x1 + wMask - 1;
        y2 = y1 + hMask - 1;

        if x1 < 1 || y1 < 1 || x2 > W || y2 > H
            intensidades(i) = 1; % claro = não preenchido
            continue;
        end

        recorte = G(y1:y2, x1:x2);
        intensidades(i) = mean(recorte(mask));  % 0 preto, 1 branco
    end

    limiar = 0.6; % quanto menor, mais exigente (mais escuro)
    filledMask = intensidades < limiar;

    centersFilled = centers(filledMask,:);
    radiiFilled = radii(filledMask);
    nPreenchidos = sum(filledMask);

    fprintf('Círculos preenchidos detectados: %d\n', nPreenchidos);

    % DEBUG
    if debugPlot
        figure;
        imshow(I); hold on;

        % circula todos os círculos válidos em verde
        viscircles(centers, radii, 'EdgeColor','g');

        % circula apenas os preenchidos em vermelho
        viscircles(centersFilled, radiiFilled, 'EdgeColor','r');

        title(sprintf('Total bolhas: %d   Preenchidos: %d', nTotal, nPreenchidos));
        hold off;
    end
end
