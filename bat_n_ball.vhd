LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY bat_n_ball IS
    PORT (
        v_sync : IN STD_LOGIC;
        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        bat_x : IN STD_LOGIC_VECTOR (10 DOWNTO 0); -- current bat x position
        serve : IN STD_LOGIC; -- initiates serve
        flap_btn : IN STD_LOGIC; -- Button for flapping
        speed_s1 : IN std_logic;
        speed_s2 : IN std_logic;
        speed_s3 : IN std_logic;
        speed_s4 : IN std_logic;
        red : OUT STD_LOGIC;
        green : OUT STD_LOGIC;
        blue : OUT STD_LOGIC;
        display : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
        
    );
END bat_n_ball;

ARCHITECTURE Behavioral OF bat_n_ball IS
    CONSTANT bsize : INTEGER := 8; -- ball size in pixels
    SIGNAL bat_w : INTEGER := 40; -- bat width in pixels
    CONSTANT bat_h : INTEGER := 3; -- bat height in pixels
    -- distance ball moves each frame
    SIGNAL ball_speed : STD_LOGIC_VECTOR (10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (6, 11);
    
    SIGNAL ball_speed1 : STD_LOGIC_VECTOR (10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (2, 11);
    SIGNAL ball_speed2 : STD_LOGIC_VECTOR (10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (6, 11);
    SIGNAL ball_speed3 : STD_LOGIC_VECTOR (10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (12, 11);
    SIGNAL ball_speed4 : STD_LOGIC_VECTOR (10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (18, 11);
    
    SIGNAL last_hit : STD_LOGIC := '1'; -- Signal to remember the last hit state

    SIGNAL flap_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(-10, 11); -- Upward flap motion
    SIGNAL flap_counter : INTEGER := 0; -- Counter to manage flap duration
    SIGNAL flap_active : STD_LOGIC := '0'; -- Indicates if the flap is currently active

    SIGNAL pipe_x : INTEGER RANGE -10 TO 800 := 800; -- Initialize pipe at the far right
    SIGNAL pipe2_x : INTEGER RANGE -10 TO 800 := 533; -- Initialize pipe at the far right
    SIGNAL pipe3_x : INTEGER RANGE -10 TO 800 := 267; -- Initialize pipe at the far right

    SIGNAL pipe_speed : INTEGER := 2; -- Speed of the pipe
    SIGNAL pipe_on : STD_LOGIC; -- Indicates whether the pipe is over the current pixel
    CONSTANT pipe_width : INTEGER := 10; -- Pipe width
    CONSTANT gap_height : INTEGER := 200; -- Height of the gap
    signal pipe_top_height, pipe2_top_height, pipe3_top_height : INTEGER RANGE 100 TO 300 := 150; -- Top heights
    SIGNAL random_value, pipe2_random, pipe3_random : INTEGER RANGE 100 TO 300 := 150; -- Random values
    CONSTANT screen_height : INTEGER := 800; -- Total height of the screen


    SIGNAL Dis_num : INTEGER := 0;
    
    SIGNAL ball_on : STD_LOGIC; -- indicates whether ball is at current pixel position
    SIGNAL bat_on : STD_LOGIC; -- indicates whether bat at over current pixel position
    SIGNAL game_on : STD_LOGIC := '0'; -- indicates whether ball is in play
    -- current ball position - intitialized to center of screen
    SIGNAL ball_x : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(400, 11);
    SIGNAL ball_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(300, 11);
    -- bat vertical position
    CONSTANT bat_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(500, 11);
    -- current ball motion - initialized to (+ ball_speed) pixels/frame in both X and Y directions
    SIGNAL ball_x_motion, ball_y_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := ball_speed;
BEGIN
    red <= NOT pipe_on; -- color setup for red ball and cyan bat on white background
    green <= NOT ball_on;
    blue <= NOT ball_on;
    -- process to draw round ball
    -- set ball_on if current pixel address is covered by ball position
    balldraw : PROCESS (ball_x, ball_y, pixel_row, pixel_col) IS
        VARIABLE vx, vy : STD_LOGIC_VECTOR (10 DOWNTO 0); -- 9 downto 0
    BEGIN
        IF pixel_col <= ball_x THEN -- vx = |ball_x - pixel_col|
            vx := ball_x - pixel_col;
        ELSE
            vx := pixel_col - ball_x;
        END IF;
        IF pixel_row <= ball_y THEN -- vy = |ball_y - pixel_row|
            vy := ball_y - pixel_row;
        ELSE
            vy := pixel_row - ball_y;
        END IF;
        IF ((vx * vx) + (vy * vy)) < (bsize * bsize) THEN -- test if radial distance < bsize
            ball_on <= game_on;
        ELSE
            ball_on <= '0';
        END IF;
    END PROCESS;
    
    randomizer : PROCESS
    BEGIN
        WAIT UNTIL rising_edge(v_sync);
        random_value <= random_value + 10;  -- Increment to simulate randomness
        IF random_value > 300 THEN  -- Reset to keep within range
            random_value <= 100;
        END IF;
    END PROCESS;
    pipedraw : PROCESS (pipe_x, pipe2_x, pipe3_x, pixel_row, pixel_col)
    BEGIN
        pipe_on <= '0'; -- Default to off

        -- Check and draw first pipe
        IF pixel_col >= pipe_x AND pixel_col < pipe_x + pipe_width THEN
            IF (pixel_row < pipe_top_height) OR (pixel_row > pipe_top_height + gap_height AND pixel_row < screen_height) THEN
                pipe_on <= '1';
            END IF;
        END IF;

        -- Check and draw second pipe
        IF pixel_col >= pipe2_x AND pixel_col < pipe2_x + pipe_width THEN
            IF (pixel_row < pipe2_top_height) OR (pixel_row > pipe2_top_height + gap_height AND pixel_row < screen_height) THEN
                pipe_on <= '1';
            END IF;
        END IF;

        -- Check and draw third pipe
        IF pixel_col >= pipe3_x AND pixel_col < pipe3_x + pipe_width THEN
            IF (pixel_row < pipe3_top_height) OR (pixel_row > pipe3_top_height + gap_height AND pixel_row < screen_height) THEN
                pipe_on <= '1';
            END IF;
        END IF;
    END PROCESS;
    
   
    
move_pipes : PROCESS
BEGIN
    WAIT UNTIL rising_edge(v_sync);
    display <= std_logic_vector(to_unsigned(Dis_num, display'length));

    -- Move and reset the first pipe
    IF pipe_x > 0 THEN
        pipe_x <= pipe_x - pipe_speed;
    ELSE
        pipe_x <= 800;
        pipe_top_height <= random_value;
    END IF;

    -- Move and reset the second pipe
    IF pipe2_x > 0 THEN
        pipe2_x <= pipe2_x - pipe_speed;
    ELSE
        pipe2_x <= 800;
        pipe2_top_height <= pipe2_random;
    END IF;

    -- Move and reset the third pipe
    IF pipe3_x > 0 THEN
        pipe3_x <= pipe3_x - pipe_speed;
    ELSE
        pipe3_x <= 800;
        pipe3_top_height <= pipe3_random;
    END IF;

    -- Score update for crossing the middle
    IF (pipe_x + pipe_width <= 400) AND (pipe_x + pipe_width > 398) AND game_on = '1' THEN
        Dis_num <= Dis_num + 1;
    END IF;
    
    IF (pipe2_x + pipe_width <= 400) AND (pipe2_x + pipe_width > 398) AND game_on = '1' THEN
        Dis_num <= Dis_num + 1;
    END IF;
    
    IF (pipe3_x + pipe_width <= 400) AND (pipe3_x + pipe_width > 398) AND game_on = '1' THEN
        Dis_num <= Dis_num + 1;
    END IF;


    -- Reset score when game is over
    IF game_on = '0' THEN
        Dis_num <= 0;
    END IF;

END PROCESS;

    
    -- process to move ball once every frame (i.e., once every vsync pulse)
    mball : PROCESS
        VARIABLE temp : STD_LOGIC_VECTOR (11 DOWNTO 0);
    BEGIN
    WAIT UNTIL rising_edge(v_sync);
    IF flap_btn = '1' AND game_on = '1' AND flap_active = '0' THEN
        -- Start the flap
        flap_active <= '1';
        flap_counter <= 5; -- Set for 50 cycles of flap effect
        ball_y_motion <= CONV_STD_LOGIC_VECTOR(-10, 11); -- Reverses the speed for flap effect
    ELSIF flap_counter > 0 THEN
        -- Decrement flap counter if flap is active
        flap_counter <= flap_counter - 1;
    ELSIF flap_counter = 0 AND flap_active = '1' THEN
        -- End the flap and return to normal motion
        flap_active <= '0';
        ball_y_motion <= ball_speed; -- Restore normal falling speed
    END IF;
    
    IF serve = '1' AND game_on = '0' THEN -- test for new serve
        game_on <= '1';
        
        ball_x <= CONV_STD_LOGIC_VECTOR(400, 11);  -- Center X position (half of 800)
        ball_y <= CONV_STD_LOGIC_VECTOR(300, 11);  -- Center Y position (half of 600)
        -- Update both motions to be negative initially
        ball_x_motion <= (OTHERS => '0');
        ball_y_motion <= (NOT ball_speed) - 1;
    ELSIF ball_y <= bsize THEN -- bounce off top wall
        ball_y_motion <= ball_speed; -- set vspeed to (+ ball_speed) pixels
    ELSIF ball_y + bsize >= 600 THEN -- if ball meets bottom wall
        ball_y_motion <= (NOT ball_speed) + 1; -- set vspeed to (- ball_speed) pixels
        game_on <= '0'; -- and make ball 
    END IF;

        -- Check for collision with the top part of the pipe
        -- Check for collision with the top part of each pipe
        IF (ball_y - bsize/2) <= pipe_top_height THEN
            IF (ball_x + bsize/2) >= pipe_x AND (ball_x - bsize/2) <= (pipe_x + pipe_width) THEN
                game_on <= '0'; -- Collision detected, game over with the first pipe
            END IF;
        END IF;
        
        IF (ball_y - bsize/2) <= pipe2_top_height THEN
            IF (ball_x + bsize/2) >= pipe2_x AND (ball_x - bsize/2) <= (pipe2_x + pipe_width) THEN
                game_on <= '0'; -- Collision detected, game over with the second pipe
            END IF;
        END IF;
        
        IF (ball_y - bsize/2) <= pipe3_top_height THEN
            IF (ball_x + bsize/2) >= pipe3_x AND (ball_x - bsize/2) <= (pipe3_x + pipe_width) THEN
                game_on <= '0'; -- Collision detected, game over with the third pipe
            END IF;
        END IF;
        
        -- Check for collision with the bottom part of each pipe
        IF (ball_y + bsize/2) >= (pipe_top_height + gap_height) THEN
            IF (ball_x + bsize/2) >= pipe_x AND (ball_x - bsize/2) <= (pipe_x + pipe_width) THEN
                game_on <= '0'; -- Collision detected, game over with the first pipe
            END IF;
        END IF;
        
        IF (ball_y + bsize/2) >= (pipe2_top_height + gap_height) THEN
            IF (ball_x + bsize/2) >= pipe2_x AND (ball_x - bsize/2) <= (pipe2_x + pipe_width) THEN
                game_on <= '0'; -- Collision detected, game over with the second pipe
            END IF;
        END IF;
        
        IF (ball_y + bsize/2) >= (pipe3_top_height + gap_height) THEN
            IF (ball_x + bsize/2) >= pipe3_x AND (ball_x - bsize/2) <= (pipe3_x + pipe_width) THEN
                game_on <= '0'; -- Collision detected, game over with the third pipe
            END IF;
        END IF;
        
    
        -- compute next ball vertical position
        -- variable temp adds one more bit to calculation to fix unsigned underflow problems
        -- when ball_y is close to zero and ball_y_motion is negative
        temp := ('0' & ball_y) + (ball_y_motion(10) & ball_y_motion);
        IF game_on = '0' THEN
            ball_y <= CONV_STD_LOGIC_VECTOR(440, 11);
        ELSIF temp(11) = '1' THEN
            ball_y <= (OTHERS => '0');
        ELSE ball_y <= temp(10 DOWNTO 0); -- 9 downto 0
        END IF;
        -- compute next ball horizontal position
        -- variable temp adds one more bit to calculation to fix unsigned underflow problems
        -- when ball_x is close to zero and ball_x_motion is negative
        -- Remove or comment out any updating of ball_x based on ball_x_motion
        -- temp := ('0' & ball_x) + (ball_x_motion(10) & ball_x_motion);
        -- IF temp(11) = '1' THEN
        --     ball_x <= (OTHERS => '0');
        -- ELSE ball_x <= temp(10 DOWNTO 0);
        -- END IF;
        
    END PROCESS;
    

    
END Behavioral;
