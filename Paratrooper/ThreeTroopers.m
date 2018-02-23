%script for animating solution to the three paratrooper problem

%I'm using polar coordinates for this, because it makes it all easier. If
%you wanted, you could started with random cartesian locations for the
%three troopers, then calculate the circle they encompas

rng(8);
gifName = 'paratroopers.gif';
frameDelay = 0.04;

%speed (in degrees/tick)
speed = 4;

r = 1; %radius of troopers
centre = [0, 0]; %centre of the trooper circle

%angles of each trooper (degrees)
troopAng = floor(rand(3, 1) * 360/speed)*speed;

%waketime for each
%wakeTick = ceil(rand(3, 1) * 100);
wakeTick = [30, 10, 40];
awake = zeros(3, 1);


f = figure('Position', [350 350 200 200]);
a = axes('Position', [0 0 1 1]);
troopPlot = scatter(r*cosd(troopAng) + centre(1), r*sind(troopAng) + centre(2),...
    [10^2 20^2 30^2], [1 0 0; 0 0 1; 0 0.8 0]);
hold on
xlim([-1.1 1.1]);
ylim([-1.1 1.1]);
axis square;
rectangle('Position', [centre(1)-r, centre(2)-r, r*2, r*2], ...
    'Curvature', 1, 'LineStyle', '--');

infoText = text(centre(1)-0.4, centre(2), {...
    'A: sleeping'
    'B: sleeping'
    'C: sleeping'}, 'HorizontalAlignment', 'left', 'FontSize', 8);

a.XAxis.Visible = 'off';
a.YAxis.Visible = 'off';

for tick=(1:5000)
    %wake up sleepy heads
    if wakeTick(1) == tick
        awake(1) = 1;
        infoText.String{1} = 'A: waiting';
    end
    if wakeTick(2) == tick
        awake(2) = 1;
        infoText.String{2} = 'B: circling';
    end
    if wakeTick(3) == tick
        awake(3) = 1;
        CSavedPositions = troopAng(1:2);
        CTarget = 1;
        CWait = 0;
        plot(r*cosd(troopAng(2)) + centre(1), r*sind(troopAng(2)) + centre(2),...
            'Marker', 'x', 'Color', [0 0.8 0], 'MarkerSize', 10);
        plot(r*cosd(troopAng(1)) + centre(1), r*sind(troopAng(1)) + centre(2), ...
            'Marker', '*', 'Color', [1 0 0], 'MarkerSize', 5);
    end
    
    %B just walks in circles
    if awake(2)
       troopAng(2) = mod(troopAng(2) + speed, 360); 
    end
    
    %C goes between the two position he knows
    if awake(3)
        %if he's walking
        if CWait==0
            if troopAng(3) == CSavedPositions(CTarget+1)
                CWait = 360/speed;
                CTarget = mod(CTarget + 1, 2);
                infoText.String{3} = 'C: waiting for B to circle once';
            else
                troopAng(3) = mod(troopAng(3) + speed, 360);
                if CTarget == 0
                    infoText.String{3} = 'C: walking towards point *';
                else
                    infoText.String{3} = 'C: walking towards point x';
                end
            end
        else %if he's waiting
            CWait = CWait - 1;
        end
    end
    troopPlot.XData = r*cosd(troopAng) + centre(1);
    troopPlot.YData = r*sind(troopAng) + centre(2);
    drawnow;
    
    if all(troopAng == troopAng(1))
        break
    end
    pause(frameDelay);
    
    if ~isempty(gifName)
        frame = getframe(f);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        if tick == 1
            imwrite(imind,cm,gifName,'gif', 'Loopcount',inf, 'DelayTime',frameDelay);
        else
            imwrite(imind,cm,gifName,'gif','WriteMode','append', 'DelayTime',frameDelay);
        end
    end
    
end
