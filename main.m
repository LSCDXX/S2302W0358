%%  ��ջ���
warning off             % �رձ�����Ϣ
close all               % �رտ�����ͼ��
clear                   % ��ձ���
clc                     % ���������


%%  �������ݣ�ʱ�����еĵ������ݣ�
result = xlsread('��ͬʱ�����ݱ仯.xlsx');

%%  ���ݷ���
num_samples = length(result);  % �Ա����������ʶ��Ϊ����������Ϊ119
kim = 17;                      % ��ʱ��������������ת����������������17*7=119
zim =  1;                      % ��1��ʱ������Ԥ�⣬��Ԥ����һ����

%%  �������ݼ�������ת��Ϊ����
for i = 1: num_samples - kim - zim + 1
    res(i, :) = [reshape(result(i: i + kim - 1), 1, kim), result(i + kim + zim - 1)];
end

%%  ���ݼ�����
outdim = 1;                                  % �����һ��Ϊ���
num_size = 0.7;                              % ����ѵ����ռ���ݼ�����
num_train_s = round(num_size * num_samples); % ����ѵ������������
f_ = size(res, 2) - outdim;                  % ��������ά�ȣ������Ա�����ʱ�䣩


P_train = res(1: num_train_s, 1: f_)';       %ѵ��������������֤ת��������
T_train = res(1: num_train_s, f_ + 1: end)'; %ѵ����Ŀ��
M = size(P_train, 2);                        %����

P_test = res(num_train_s + 1: end, 1: f_)';
T_test = res(num_train_s + 1: end, f_ + 1: end)';
N = size(P_test, 2);

%%  ���ݴ������������紦��ģ��
[p_train, ps_input] = mapminmax(P_train, 0, 1);   %��������Ԥ������һ��
p_test = mapminmax('apply', P_test, ps_input);

[t_train, ps_output] = mapminmax(T_train, 0, 1);  %�������Ԥ����
t_test = mapminmax('apply', T_test, ps_output);

net = newff(p_train, t_train, 5);                 %����ģ��

%%  ����ѵ������
net.trainParam.epochs = 10000;    %�������� 
net.trainParam.goal = 1e-6;       %�����ֵ
net.trainParam.lr = 0.01;         %ѧϰ��

net= train(net, p_train, t_train);

%%  �������
t_sim1 = sim(net, p_train);
t_sim2 = sim(net, p_test);

T_sim1 = mapminmax('reverse', t_sim1, ps_output);    %����ԭʼ���ݣ�����һ��
T_sim2 = mapminmax('reverse', t_sim2, ps_output);

error1 = sqrt(sum((T_sim1 - T_train).^2) ./ M);      %����ѵ�����������
error2 = sqrt(sum((T_sim2 - T_test ).^2) ./ N);      %������Ծ��������

%%  ��ͼ
figure
plot(1: M, T_train, 'r-', 1: M, T_sim1, 'b-', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {strcat('ѵ����Ԥ�����Աȣ�', ['RMSE=' num2str(error1)])};   %��ͷ������ʾ���������
title(string)
xlim([1, M])
grid

figure
plot(1: N, T_test, 'r-', 1: N, T_sim2, 'b-', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {strcat('���Լ�Ԥ�����Աȣ�', ['RMSE=' num2str(error2)])};
title(string)
xlim([1, N])
grid

%%  ���ָ�����
% R2������ϵ����0��1��
R1 = 1 - norm(T_train - T_sim1)^2 / norm(T_train - mean(T_train))^2;
R2 = 1 - norm(T_test  - T_sim2)^2 / norm(T_test  - mean(T_test ))^2;

disp(['ѵ�������ݵ�R2Ϊ��', num2str(R1)])
disp(['���Լ����ݵ�R2Ϊ��', num2str(R2)])

% MAE��ƽ���������
mae1 = sum(abs(T_sim1 - T_train)) ./ M ;
mae2 = sum(abs(T_sim2 - T_test )) ./ N ;

disp(['ѵ�������ݵ�MAEΪ��', num2str(mae1)])
disp(['���Լ����ݵ�MAEΪ��', num2str(mae2)])

% MBE��ƽ��ƫ�����
mbe1 = sum(T_sim1 - T_train) ./ M ;
mbe2 = sum(T_sim2 - T_test ) ./ N ;

disp(['ѵ�������ݵ�MBEΪ��', num2str(mbe1)])
disp(['���Լ����ݵ�MBEΪ��', num2str(mbe2)])

%  MAPE��ƽ�����԰ٷֱ����
mape1 = sum(abs((T_sim1 - T_train)./T_train)) ./ M ;
mape2 = sum(abs((T_sim2 - T_test )./T_test )) ./ N ;

disp(['ѵ�������ݵ�MAPEΪ��', num2str(mape1)])
disp(['���Լ����ݵ�MAPEΪ��', num2str(mape2)])

%%  ����ɢ��ͼ
sz = 25;
c = 'b';

figure
scatter(T_train, T_sim1, sz, c)
hold on
plot(xlim, ylim, '--k')
xlabel('ѵ������ʵֵ');
ylabel('ѵ����Ԥ��ֵ');
xlim([min(T_train) max(T_train)])
ylim([min(T_sim1) max(T_sim1)])
title('ѵ����Ԥ��ֵ vs. ѵ������ʵֵ')

figure
scatter(T_test, T_sim2, sz, c)
hold on
plot(xlim, ylim, '--k')
xlabel('���Լ���ʵֵ');
ylabel('���Լ�Ԥ��ֵ');
xlim([min(T_test) max(T_test)])
ylim([min(T_sim2) max(T_sim2)])
title('���Լ�Ԥ��ֵ vs. ���Լ���ʵֵ')
