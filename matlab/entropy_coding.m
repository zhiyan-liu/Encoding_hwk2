function [codebook] = entropy_coding(image, num_symbol)
if num_symbol == 1
    symbol_list = unique(image)';
    N = length(symbol_list);
    L = numel(image);
    prob_list = zeros(1,N);
    for iter = 1:N
        prob_list(iter) = sum(sum(find(image==symbol_list(iter))))/L;
    end
    X = huffmanCoding(num2cell(symbol_list),prob_list, 0.001);
    codebook = gen_codebook(X, 0, 0);
elseif num_symbol == 2
    value_list = unique(image)';
    N = length(value_list) ^ 2;
    L = numel(image) / 2;
    symbol_list = cell(1,N);
    prob_list = zeros(1,N);
    width = size(image, 2);
    odd_cols = image(:,1:2:width);
    even_cols = image(:,2:2:width);
    for x = 1:length(value_list)
        for y = 1:length(value_list)
            symbol_list{N*x+y-N} = [value_list(x), value_list(y)];
            prob_list(N*x+y-N) = sum(sum((odd_cols==value_list(x)) & (even_cols == value_list(y))))/L;
        end
    end
    symbol_list(prob_list == 0) = [];
    prob_list(prob_list == 0) = [];
    X = huffmanCoding(symbol_list,prob_list,0.001);
    codebook = gen_codebook(X, 1, 0);
end
end

