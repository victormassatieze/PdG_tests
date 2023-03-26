function output = getMSE(target,test)
    E = sum(abs(target).^2,"all")/size(target,2);
    Ep = sum(abs(test).^2,"all")/size(test,2);
    output = sum(abs((target)./sqrt(E) - (test)./sqrt(Ep)).^2,"all");
end