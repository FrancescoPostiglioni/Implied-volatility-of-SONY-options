clc
close all
clear

%% Problem Set 1 - 05/10/2023 %
% Francesco Postiglioni n. 788731 %
% Andrea Formisano n. 787681 %

%% In this code data from the Chicago Board of Options Exchange (CBOE) is
% analized and processed. More specifically, regarding the SONY stock,
% available data for the stock's option chain in a time period spanning
% from Oct 23 to Apr 24 is analyzed and processed to find the implied
% volatility for each call option thanks to blsimpv() function. 
% Each option will be a point coordinates of which are the triplets formed
% by its maturity, strike price and implied volatility. All the options
% will be scattered in a 3d graph with an interpolating function. This
% function will then come to use in order to price a new - not negotiated -
% option thanks to the Black & Scholes method.

%% Start by importing the necessary data from 
% https://www.cboe.com/delayed_quotes/sony/quote_table
ott23 = readtable('./data/sony_quotedata_ott23.csv', ...
    VariableNamingRule='preserve');
nov23 = readtable('./data/sony_quotedata_nov23.csv', ...
    VariableNamingRule='preserve');
gen24 = readtable('./data/sony_quotedata_gen24.csv', ...
    VariableNamingRule='preserve');
apr24 = readtable('./data/sony_quotedata_apr24.csv', ...
    VariableNamingRule='preserve');

%% Organizing data
value = [ott23.("Last Sale"); nov23.("Last Sale"); gen24.("Last Sale");
    apr24.("Last Sale")];
strike = [ott23.Strike; nov23.Strike; gen24.Strike; apr24.Strike];
% Days to maturity counting from today
days = [repelem(1, 6)'; repelem(8, 6)'; repelem(15, 6)'; repelem(22, 6)'; ...
    repelem(29, 6)'; repelem(36, 6)'; repelem(43, 6)'; repelem(50, 6)'; ...
    repelem(106, 6)'; repelem(197, 6)'];
datamatrix = table(days, value, strike);

% Defining a 'risk-free' rate using the rate of return of the 3M treasury
% bills (T-Bills) for the date 05/10) 
% from https://ycharts.com/indicators/3_month_T_bill
r_free = 0.0534;
% Defining - at the same time - the SONY stock price for the date 05/10
% from https://finance.yahoo.com/quote/SONY/history
s0_price = 82.86;

% Creating a matrix of zeros to store the triplets (coordinates of
% maturity-strike-implied volatility)
options = zeros(60,3);
names = {'Maturity', 'Strike', 'ImpVol'};
options = array2table(options, "VariableNames", names);

%% Finding implied volatility for each option thanks to blsimpv()
for i = 1:60
    options.Maturity(i) = datamatrix.days(i) ./ 360;
    options.Strike(i) = datamatrix.strike(i);

    % Finding implied volatility from Black & Scholes
    impv = blsimpv(s0_price,datamatrix.strike(i),r_free,options.Maturity(i), ...
        datamatrix.value(i));
    options.ImpVol(i) = impv;
end

% Due to external problems blsimpv() function sometimes fails to deliver an
% output and delivers a NaN, let's clean the array to represent the
% options with a defined implied volatility
options = table2array(options);
options(any(isnan(options), 2), :) = [];
options = array2table(options, "VariableNames", names);

%% Let's now represent the corresponding triplets in a 3d space with an
% interpolating function
figure;
scatter3(options.Maturity, options.Strike, options.ImpVol, 'filled', 'm');
title('Scattered Sony call options');
xlabel('Maturity');
ylabel('Strike price');
zlabel('Implied volatility');
legend('Options')
filename1 = './output/Scattered Sony call options.png';
print('-dpng', filename1);

%% Given the points we can extrapolate an interpolating 3d function in R3
Function = scatteredInterpolant(options.Maturity, options.Strike, ...
    options.ImpVol, 'natural');
[xq, yq] = meshgrid((min(options.Maturity)):0.01:(max(options.Maturity)), ...
    (min(options.Strike)):0.01:(max(options.Strike)));
vq = griddata(options.Maturity, options.Strike, options.ImpVol, xq, yq);
voq = Function(xq, yq);

% Let's see it
figure;
scatter3(options.Maturity, options.Strike, options.ImpVol, 'filled', 'm');
hold on;
mesh(xq, yq, vq);
title('Sony stock volatility surface');
xlabel('Maturity');
ylabel('Strike price');
zlabel('Implied volatility');
legend('Sony options', 'Volatility surface');
filename2 = './output/Sony stock volatility surface.png';
print('-dpng', filename2);

%% Let's see it from Function output (smoother)
figure;
scatter3(options.Maturity, options.Strike, options.ImpVol, 'filled', 'm');
hold on; 
surface = mesh(xq, yq, voq);
title('Sony stock volatility surface function');
xlabel('Maturity');
ylabel('Strike price');
zlabel('Implied volatility');
legend('Sony options', 'Volatility surface');
filename3 = './output/Sony stock volatility surface function.png';
print('-dpng', filename3);

%% Let's now - using the interpolated function from the previous data - find
% the correspondent implied volatility for an unlisted strike price and
% maturity
new_strike = 87;
new_maturity_days = 29 ./ 360;
new_impvol = interp2(xq, yq, voq, new_maturity_days, new_strike);
new_price = blsprice(s0_price, new_strike, r_free, new_maturity_days,new_impvol);

%% The implied volatility of the unlisted SONY option contract - found as
%% the z-coordinate of the function given a new strike and a new maturity -
%% is used as an input by the blsprice fuction that prices the new option at
%% ∼ $ 1.72 with a strike price of $ 87 and an expiration date of 29 days.
