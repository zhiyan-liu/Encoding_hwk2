src_quant_conf.type = 'h.261'; % 'h.261', 'custom'
if strcmp(src_quant_conf.type, 'uniform')
    src_quant_conf.step = 4;
elseif strcmp(src_quant_conf.type, 'h.261')
    src_quant_conf.factor = 10;
elseif strcmp(src_quant_conf.type, 'custom')
    src_quant_conf.quant_array = [10, 20, 30, 40];
end