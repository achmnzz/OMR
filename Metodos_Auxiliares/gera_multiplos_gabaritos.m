function gera_multiplos_gabaritos(gabaritos, pastaSaida)
    % CRIA PASTA DE SAÍDA SE NÃO EXISTIR
    if ~exist(pastaSaida, "dir")
        mkdir(pastaSaida);
    end

    % TIPOS DE PROVA EXISTENTES
    tipos = 'ABCD';

    % LOOP PRA GERAR TODAS AS FOLHAS
    for k = 1:numel(tipos)
        tipo = tipos(k);

        % OBTÉM O GABARITO CORRESPONDENTE
        if isfield(gabaritos, tipo)
            g = gabaritos.(tipo);
        else
            warning("Gabarito da prova %c não encontrado!", tipo);
            continue;
        end

        % CRIA NOME FINAL DO ARQUIVO
        nomeArquivo = fullfile(pastaSaida, ...
            sprintf("folha_resposta_%c.png", tipo));

        % GERA A IMAGEM
        gera_folha_resposta_e_gabarito(tipo, g, nomeArquivo);

        fprintf("Folha resposta %c gerada: %s\n", tipo, nomeArquivo);
    end

    disp("Todas as folhas-resposta foram geradas com sucesso!");

end