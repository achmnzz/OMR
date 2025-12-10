function criar_gabaritos
    gabaritos.A = randi([1 5], 1, 50);
    gabaritos.B = randi([1 5], 1, 50);
    gabaritos.C = randi([1 5], 1, 50);
    gabaritos.D = randi([1 5], 1, 50);
    
    save('gabaritos.mat', 'gabaritos');
    
    disp('gabaritos.mat criado com sucesso!');
end