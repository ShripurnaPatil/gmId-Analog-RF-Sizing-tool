function gmId_Sizing_tool()
    cache = fullfile(pwd, 'PDK_LUT.mat');
    if isfile(cache), s = load(cache); LUT = s.LUT;
    else, LUT = loadFolders(cache); if isempty(LUT), return; end; end

    f = uifigure('Name', 'gm/Id Analog & RF Sizing Studio', 'Position', [60 50 1160 670], 'Color', [0.96 0.97 0.98]);
    p = uipanel(f, 'Title', 'Sizing Controls', 'FontWeight', 'bold', 'Position', [12 12 310 645], 'BackgroundColor', 'w');

    btnLoad = uibutton(p, 'Text', 'Load New CSV Folders...', 'Position', [12 590 285 25], 'BackgroundColor', [0.88 0.93 1], 'FontWeight', 'bold');
    uilabel(p, 'Text', 'Device:', 'Position', [12 552 55 22], 'FontWeight', 'bold');
    ddDev = uidropdown(p, 'Items', {'PMOS', 'NMOS'}, 'Value', 'PMOS', 'Position', [70 552 95 25]);
    ddRole = uidropdown(p, 'Items', {'DiffPair(24)','Load(18)','Mirror(14)','RF_LNA(10)','RF_Mix(7)','Manual'}, 'Position', [173 552 124 25]);

    uilabel(p, 'Text', 'Length L (um):', 'Position', [12 512 95 22], 'FontWeight', 'bold');
    ddLen = uidropdown(p, 'Position', [110 512 90 25]);
    efLen = uieditfield(p, 'numeric', 'Position', [208 512 89 25], 'ValueDisplayFormat', '%.2f');
    sldLen = uislider(p, 'Position', [18 494 275 3]);
    cbOver = uicheckbox(p, 'Text', 'Overlay All Lengths on Plots', 'Position', [12 444 200 22]);

    uilabel(p, 'Text', 'gm/Id (1/V):', 'Position', [12 406 85 22], 'FontWeight', 'bold');
    efGm = uieditfield(p, 'numeric', 'Value', 24, 'Limits', [3 28], 'Position', [215 406 82 25], 'ValueDisplayFormat', '%.2f');
    sldGm = uislider(p, 'Limits', [4 27], 'Value', 24, 'Position', [18 388 275 3], 'MajorTicks', [5 10 15 20 25]);

    ddMode = uidropdown(p, 'Items', {'Id (nA)','Id (uA)','gm (uS)','gm (mS)'}, 'Position', [12 330 120 25]);
    efVal = uieditfield(p, 'numeric', 'Value', 10, 'Position', [140 330 157 25], 'ValueDisplayFormat', '%.3f');

    txt = uitextarea(p, 'Position', [12 15 285 300], 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 10.5, 'BackgroundColor', [0.95 0.98 0.96]);

    ax1 = uiaxes(f, 'Position', [340 345 395 310], 'BackgroundColor', 'w');
    ax2 = uiaxes(f, 'Position', [750 345 395 310], 'BackgroundColor', 'w');
    ax3 = uiaxes(f, 'Position', [340 15 395 310],  'BackgroundColor', 'w');
    ax4 = uiaxes(f, 'Position', [750 15 395 310],  'BackgroundColor', 'w');

    function initLen()
        Lv = LUT.(ddDev.Value).L_vec * 1e6; N = length(Lv);
        items = arrayfun(@(x) sprintf('%.2f', x), Lv, 'UniformOutput', false);
        ddLen.Items = items; idx0 = max(1, round(N*0.75));
        ddLen.Value = items{idx0}; efLen.Limits = [min(Lv) max(Lv)]; efLen.Value = Lv(idx0);
        if N > 1
            sldLen.Enable='on'; sldLen.Limits=[1 N];
            tIdx = unique(round(linspace(1, N, min(4, N))));
            sldLen.MajorTicks = tIdx; sldLen.MajorTickLabels = items(tIdx);
            sldLen.MinorTicks = 1:N; sldLen.Value = idx0;
        else, sldLen.Enable='off'; end
    end

    ddLen.ValueChangedFcn = @(~,~) setL(str2double(ddLen.Value));
    efLen.ValueChangedFcn = @(~,~) setL(efLen.Value);
    sldLen.ValueChangingFcn = @(~,e) setLIdx(round(e.Value));
    sldLen.ValueChangedFcn  = @(s,~) setLIdx(round(s.Value));
    function setLIdx(k), Lv = LUT.(ddDev.Value).L_vec*1e6; k = max(1,min(length(Lv),k)); setL(Lv(k)); end
    function setL(v)
        Lv = LUT.(ddDev.Value).L_vec*1e6; [~,k] = min(abs(Lv-v));
        efLen.Value = v; if length(Lv)>1, sldLen.Value = k; end
        if abs(Lv(k)-v)<1e-4, ddLen.Value = sprintf('%.2f', Lv(k)); end; update();
    end

    btnLoad.ButtonPushedFcn = @(~,~) reload();
    function reload(), nL = loadFolders(cache); if ~isempty(nL), LUT = nL; initLen(); update(); end; end
    ddDev.ValueChangedFcn = @(~,~) initAndUp();
    function initAndUp(), initLen(); update(); end
    ddRole.ValueChangedFcn = @(~,~) setRole();
    function setRole()
        r = ddRole.Value;
        if contains(r,'24'), syncG(24); elseif contains(r,'18'), syncG(18); elseif contains(r,'14'), syncG(14);
        elseif contains(r,'10'), syncG(10); elseif contains(r,'7'), syncG(7); else, update(); end
    end
    sldGm.ValueChangingFcn = @(~,e) syncG(e.Value); sldGm.ValueChangedFcn = @(s,~) syncG(s.Value);
    efGm.ValueChangedFcn = @(s,~) syncG(s.Value);
    function syncG(v), efGm.Value = v; if v>=4 && v<=27, sldGm.Value = v; end; update(); end
    cbOver.ValueChangedFcn = @(~,~) update(); ddMode.ValueChangedFcn = @(~,~) update(); efVal.ValueChangedFcn = @(~,~) update();

    function update()
        dev = ddDev.Value; Lum = efLen.Value; gmId = efGm.Value; Lv = LUT.(dev).L_vec*1e6; N = length(Lv);
        [~,nk] = min(abs(Lv-Lum)); D = LUT.(dev).data(nk);
        idwL = zeros(1,N); gL = zeros(1,N); ftL = zeros(1,N); vL = zeros(1,N);
        for k=1:N
            Dk = LUT.(dev).data(k); [~,pk] = max(Dk.gm_id); [gu,u] = unique(Dk.gm_id(pk:end),'stable');
            idwL(k)=interp1(gu,Dk.Id_W(pk+u-1),gmId,'pchip','extrap'); gL(k)=interp1(gu,Dk.gm_gds(pk+u-1),gmId,'pchip','extrap');
            ftL(k)=interp1(gu,Dk.fT(pk+u-1),gmId,'pchip','extrap'); vL(k)=interp1(gu,Dk.VGS(pk+u-1),gmId,'pchip','extrap');
        end
        if N>1, idw=interp1(Lv,idwL,Lum,'pchip','extrap'); gain=interp1(Lv,gL,Lum,'pchip','extrap'); ft=interp1(Lv,ftL,Lum,'pchip','extrap'); vgs=interp1(Lv,vL,Lum,'pchip','extrap');
        else, idw=idwL(1); gain=gL(1); ft=ftL(1); vgs=vL(1); end

        switch ddMode.Value
            case 'Id (nA)', Id=efVal.Value*1e-9; gm=gmId*Id; case 'Id (uA)', Id=efVal.Value*1e-6; gm=gmId*Id;
            case 'gm (uS)', gm=efVal.Value*1e-6; Id=gm/gmId; case 'gm (mS)', gm=efVal.Value*1e-3; Id=gm/gmId;
        end
        Wum = (Id/idw)*1e6; Cgg = (gm/(2*pi*ft))*1e15;

        txt.Value = {sprintf('%s | L = %.2f um | gm/Id = %.2f',dev,Lum,gmId), '==================================', ...
            sprintf('Drain Id     : %.3f nA (%.3f uA)',Id*1e9,Id*1e6), sprintf('Transc. gm   : %.3f uS',gm*1e6), ...
            sprintf('TOTAL WIDTH  : %.3f um (~%d fing.)',Wum,max(1,round(Wum/2))), '==================================', ...
            sprintf('Intrinsic Av : %.1f V/V (%.1f dB)',gain,20*log10(abs(gain))), sprintf('Transit fT   : %.1f MHz',ft/1e6), ...
            sprintf('Est. |VGS|   : %.3f V',vgs), sprintf('Gate Cap Cgg : %.2f fF',Cgg), sprintf('Id/W Density : %.3f nA/um',idw*1e3)};

        cla(ax1); cla(ax2); cla(ax3); cla(ax4); hold(ax1,'on'); hold(ax2,'on'); hold(ax3,'on'); hold(ax4,'on');
        if cbOver.Value
            for k=1:N, Dk=LUT.(dev).data(k); vk=Dk.gm_id>=3;
                plot(ax1,Dk.gm_id(vk),Dk.gm_gds(vk),'Color',[.8 .8 .8]); plot(ax2,Dk.gm_id(vk),Dk.Id_W(vk)*1e3,'Color',[.8 .8 .8]);
                plot(ax3,Dk.gm_id(vk),Dk.fT(vk)/1e6,'Color',[.8 .8 .8]); plot(ax4,Dk.VGS,Dk.gm_id,'Color',[.8 .8 .8]);
            end
        end
        v = D.gm_id>=3;
        plot(ax1,D.gm_id(v),D.gm_gds(v),'Color',[0 .45 .74],'LineWidth',2); xline(ax1,gmId,'--r','Alpha',.4); yline(ax1,gain,'--r','Alpha',.4);
        plot(ax1,gmId,gain,'ro','MarkerSize',7,'MarkerFaceColor','r'); text(ax1,gmId,gain,sprintf(' (%.1f, %.1f)',gmId,gain),'FontWeight','bold','Color',[.8 0 0]);
        title(ax1,'1. Intrinsic Gain (g_m/g_{ds})'); xlabel(ax1,'g_m/I_D (V^{-1})'); ylabel(ax1,'Gain (V/V)'); grid(ax1,'on');

        plot(ax2,D.gm_id(v),D.Id_W(v)*1e3,'Color',[.85 .33 .1],'LineWidth',2); xline(ax2,gmId,'--r','Alpha',.4); yline(ax2,idw*1e3,'--r','Alpha',.4);
        plot(ax2,gmId,idw*1e3,'ro','MarkerSize',7,'MarkerFaceColor','r'); text(ax2,gmId,idw*1e3,sprintf(' (%.1f, %.2f)',gmId,idw*1e3),'FontWeight','bold','Color',[.8 0 0]);
        ax2.YScale='log'; title(ax2,'2. Current Density (I_D/W)'); xlabel(ax2,'g_m/I_D (V^{-1})'); ylabel(ax2,'I_D/W (nA/\mum)'); grid(ax2,'on');

        plot(ax3,D.gm_id(v),D.fT(v)/1e6,'Color',[.47 .67 .19],'LineWidth',2); xline(ax3,gmId,'--r','Alpha',.4); yline(ax3,ft/1e6,'--r','Alpha',.4);
        plot(ax3,gmId,ft/1e6,'ro','MarkerSize',7,'MarkerFaceColor','r'); text(ax3,gmId,ft/1e6,sprintf(' (%.1f, %.1f MHz)',gmId,ft/1e6),'FontWeight','bold','Color',[.8 0 0]);
        ax3.YScale='log'; title(ax3,'3. Transit Frequency (f_T)'); xlabel(ax3,'g_m/I_D (V^{-1})'); ylabel(ax3,'f_T (MHz)'); grid(ax3,'on');

        plot(ax4,D.VGS,D.gm_id,'Color',[.49 .18 .56],'LineWidth',2); xline(ax4,vgs,'--r','Alpha',.4); yline(ax4,gmId,'--r','Alpha',.4);
        plot(ax4,vgs,gmId,'ro','MarkerSize',7,'MarkerFaceColor','r'); text(ax4,vgs,gmId,sprintf(' (%.2fV, %.1f)',vgs,gmId),'FontWeight','bold','Color',[.8 0 0]);
        title(ax4,'4. Inversion Region (|V_{GS}|)'); xlabel(ax4,'|V_{GS}| (V)'); ylabel(ax4,'g_m/I_D (V^{-1})'); grid(ax4,'on');
    end
    initLen(); update();
end
function LUT = loadFolders(cache)
LUT = []; nD = uigetdir(pwd,'Select NMOS .vcsv Folder'); if isequal(nD,0), return; end
pD = uigetdir(nD,'Select PMOS .vcsv Folder'); if isequal(pD,0), return; end
LUT.NMOS = parseDir(nD); LUT.PMOS = parseDir(pD); save(cache,'LUT');
end

function devLUT = parseDir(fp)
fs = dir(fullfile(fp,'*.vcsv')); ns = {fs.name}; bf = ns(~contains(ns,'gm.vcsv'));
devLUT = struct(); Lv = [];
for i=1:length(bf)
    tag = erase(bf{i},'.vcsv'); gP = fullfile(fp,[tag 'gm.vcsv']); if ~isfile(gP), continue; end
    if endsWith(tag,'n'), L=str2double(erase(tag,'n'))*1e-9; elseif endsWith(tag,'u'), L=str2double(erase(tag,'u'))*1e-6; else, continue; end
    fP = fullfile(fp,bf{i}); fid=fopen(fP); fgetl(fid); h=lower(fgetl(fid)); fclose(fid); ps=split(h,';');
    cf=6; cg=2; ci=4;
    for k=2:length(ps), c=(k-1)*2; if contains(ps{k},'ft'),cf=c; elseif contains(ps{k},'gds'),cg=c; elseif contains(ps{k},'id/w'),ci=c; end; end
    d1=readmatrix(fP,'FileType','text','CommentStyle',';'); d2=readmatrix(gP,'FileType','text','CommentStyle',';');
    d1=d1(~any(isnan(d1),2),:); d2=d2(~any(isnan(d2),2),:); n=min(size(d1,1),size(d2,1));
    idx=length(Lv)+1; Lv(idx)=L; devLUT.data(idx).L=L; devLUT.data(idx).VGS=abs(d2(1:n,1));
    devLUT.data(idx).gm_id=abs(d1(1:n,1)); devLUT.data(idx).gm_gds=abs(d1(1:n,cg)); devLUT.data(idx).Id_W=abs(d1(1:n,ci)); devLUT.data(idx).fT=abs(d1(1:n,cf));
end
[devLUT.L_vec,s] = sort(Lv); devLUT.data = devLUT.data(s);
end
