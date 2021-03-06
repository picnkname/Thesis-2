function [tau, confusion_novel, error] = plot_novel(pred_table_novel, antitype, plot_it)

N_anti = numel(antitype);
tau = [];
confusion_novel = [];
error = []; 

for i = 1:N_anti
    antimodel = antitype{i}
    
    % For nicer plotting
    switch antimodel
    case 'none'
        model_name = 'Raw';
    case 'sum'
        model_name = 'P(S|X)';
    case 'entropy'
        model_name = 'Entropy';
    case 'filler'
        model_name = 'Filler';
    case 'flat'
        model_name = 'Flat';
    case 'anti_full'
        model_name = 'Full anti-model';
    case 'anti_matej'
        model_name = 'Reweighted anti-model';
    case 'combination'
        model_name = 'Combination of filler and anti-model';
    case 'combination2'
        model_name = 'Combination of flat and anti-model';
    end
    
    truth = pred_table_novel(:,1,i);
    class = pred_table_novel(:,2,i);
    class2 = pred_table_novel(:,6,i);
    value = pred_table_novel(:,3,i);
    if strcmp(antimodel,'sum')
        value = pred_table_novel(:,4,i);
    else if strcmp(antimodel,'entropy')
            value = pred_table_novel(:,5,i);
        end
    end
    
    % ROC to determine optimal tau:
    correct = (truth ~= 100);
    %correct = (truth == class2) & (truth ~= 100);
    [truepos falsepos cutoff] = roc(correct',value');
    totalerror = (1-truepos) + falsepos;
    [error1 t] = min(totalerror);
    truepick = truepos(t); falsepick = falsepos(t);
    if t==1
        t=2;
    end
    tau1 = cutoff((t-1));
    
    % Novelty confusion table
    %confusion = confusionmat(class ~= 100,correct)
    confusion = confusionmat(class == 100,truth ==100);
    precision1 = sum(diag(confusionmat(truth(truth~=100),class(truth~=100))));
    confusion = [precision1, confusion(1,2); (confusion(1,1)-precision1) 0; confusion(2,:)];
    confusion_novel1 = mk_stochastic(confusion')';
    
    confusion_novel = cat(3,confusion_novel,confusion_novel1);
    error = cat(1,error,error1);
    tau = cat(1,tau,tau1);
    
    if plot_it
    % Built plots
    f=figure();
    subplot(1,2,1);
    plot(falsepos, truepos,'Linewidth',1.7);
    axis square; title('ROC-curve'); ylabel('recognition accuracy (%, true positive)'); xlabel('1- novelty accuracy (%, false positive)');
    hold on; plot([0 1],[0 1],'k:'); plot(falsepick,truepick,'pk','Linewidth',2); hold off;
    text(1.1,1.3,model_name,'HorizontalAlignment','center','VerticalAlignment', 'top')
    %text(1,-0.4,num2str(confusion_novel1,2));
    
    subplot(1,2,2);
    known = correct;
    %known = (truth ~=100);
    [f1 xi] = ksdensity(value(known)); plot(xi,f1,'-.','Linewidth',1.7); axis square; title('Histogram'); xlabel('P(X|S) - P(X|anti)'); ylabel('density');lim = axis; axis(lim); 
    [f2 xi] = ksdensity(value(~known)); hold on; plot(xi,f2,'r','Linewidth',1.7); legend('known','new','Location','northeast'); xlim([-1 3]); ylim([0 max([max(f1),max(f2)])]);
    if strcmp(antimodel,'sum')
        xlim([0 1]); 
    end
    if strcmp(antimodel,'none')
        xlim([0 30]); 
    end
    plot([tau1 tau1], [0 1],'k--');  hold off;

    %plot(cutoff,(totalerror/2),cutoff,falsepos,'r--',cutoff,1-truepos,'r--');
    %hold on; plot([t t], [0 1],'k-.'); hold off;
    %xlim(lim(1:2));
    %xlabel('statistic'); ylabel('error (%)'); title('Error rate plot');
    %h = legend(num2str(confusion,2),'Location','southOutside')
    
    %
    gg = figure()
    boxplot(tau');
    ax=gca;
    ax.XTickLabel = num2cell(char('A' + (1:numel(antitype))-1))
    xlabel('Models')
    ylabel('Tau')
    
    end
      
    
end

   

end

