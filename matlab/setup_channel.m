conv_encoder_conf.n = 3;    % Output bits.
conv_encoder_conf.k = 1;    % Input bits.
conv_encoder_conf.N = 4;    
conv_encoder_conf.window_factor=6;
conv_encoder_conf.trailing = true;

A = cell(conv_encoder_conf.n,1);
 
A{1} = [1, 0, 1, 1];    % 13.
A{2} = [1, 1, 0, 1];    % 15                   
A{3} = [1, 1, 1, 1];    % 17. Rate=1/3.

% Notice: Only n=2 or n=3 is supported by this platform.
conv_encoder_conf.A=A;
conv_encoder_conf.loss_func = [];

channel_conf.encoder_type = 'conv';                 % Two choices: 'conv', 'none'.
channel_conf.encoder_conf = conv_encoder_conf;  

addpath('channel_coding/');

