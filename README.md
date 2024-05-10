## Summary 
We modified the original Lab 6 Pong code to mirror the iconic mobile game Flappy Bird

## Prerequisites 
VGA Cable and Monitor that supports VGA  

Nexys A7 100t Board  

[Vivado](https://www.xilinx.com/products/design-tools/vivado.html)

[Nexys-a7-100t Board Files](./Boards/)

## Setup

### 1. Create a new RTL project pong in Vivado Quick Start
Create six new source files of file type VHDL called clk_wiz_0, clk_wiz_0_clk_wiz, vga_sync, bat_n_ball, adc_if, and pong

clk_wiz_0.vhd and clk_wiz_0_clk_wiz.vhd are the same files as in Lab 3

vga_sync.vhd, bat_n_ball.vhd, adc_if.vhd, and pong.vhd are new files for Lab 6

Create a new constraint file of file type XDC called pong

Choose Nexys A7-100T board for the project

Click 'Finish'

Click design sources and copy the VHDL code from clk_wiz_0, clk_wiz_0_clk_wiz, vga_sync.vhd, bat_n_ball.vhd, adc_if.vhd, pong.vhd (or pong_2.vhd)

Click constraints and copy the code from pong.xdc (or pong_2.xdc)

As an alternative, you can instead download files from Github and import them into your project when creating the project. The source file or files would still be imported during the Source step, and the constraint file or files would still be imported during the Constraints step.

### 2. Run synthesis  
### 3. Run implementation  
3b. (optional, generally not recommended as it is difficult to extract information from and can cause Vivado shutdown) Open implemented design  
### 4. Generate bitstream, open hardware manager, and program device  
Click 'Generate Bitstream'  

Click 'Open Hardware Manager' and click 'Open Target' then 'Auto Connect'  

Click 'Program Device' then xc7a100t_0 to download pong.bit to the Nexys A7-100T board  

## Modifications (Lab6)

### Inputs and Outputs
Inputs include speeds 1 - 4 and BTNL button is now the 'flap' button
```
    flap_btn : IN STD_LOGIC; -- Button for flapping
    speed1 : IN std_logic;
    speed2 : IN std_logic;
    speed3 : IN std_logic;
    speed4 : IN std_logic
```  
Outputs include the Display  
```
    display : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)

```




### Ball Modification
The ball changed from moving in 2 dimensions to just moving in one dimension, on the Y axis of the screen.   


The ball also only has downward velocity. When the bird flaps, the downward velocity reverses for 5 Clock Cycles.


```
    SIGNAL flap_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(-10, 11); -- Upward flap motion
    SIGNAL flap_counter : INTEGER := 0; -- Counter to manage flap duration
    SIGNAL flap_active : STD_LOGIC := '0'; -- Indicates if the flap is currently active
```
 ~~~
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
    END IF
~~~

### Bat Modification
Bat was modified to be Vertical and its size was changed to the size of the height of the screen.  
The Bat was also pushed to the right side of the screen and its x position was updated to move across the screen.  
Two bats were rendered offset by the gap width signal to make the pipe.  
Everytime a pipe reaches x = 800 it resets and changes the front pipe to a new "random value" to make it seem like the pipes change every instance.  
This was done 3 times to create 3 pipes. 

```
    SIGNAL pipe_x : INTEGER RANGE -10 TO 800 := 800; -- Initialize pipe at the far right
    SIGNAL pipe2_x : INTEGER RANGE -10 TO 800 := 533; -- Initialize pipe at the far right
    SIGNAL pipe3_x : INTEGER RANGE -10 TO 800 := 267; -- Initialize pipe at the far right

    SIGNAL pipe_speed : INTEGER := 2; -- Speed of the pipe
    SIGNAL pipe_on : STD_LOGIC; -- Indicates whether the pipe is over the current pixel
    CONSTANT pipe_width : INTEGER := 10; -- Pipe width
    CONSTANT gap_height : INTEGER := 200; -- Height of the gap
    signal pipe_top_height, pipe2_top_height, pipe3_top_height : INTEGER RANGE 100 TO 300 := 150; -- Top heights
```

```

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
```


```
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
```



### Randomizer
Random Value starts at 150 and increments every clock cycle until it hits 300 and then resets to 100.   
When a pipe reaches x = 800 the top pipe's height will be set to the random value.  
This simulates "randomness" and could definitely be more efficient but VHDL does not have a true random functionality built in for integers. 

```
randomizer : PROCESS
    BEGIN
        WAIT UNTIL rising_edge(v_sync);
        random_value <= random_value + 10;  -- Increment to simulate randomness
        IF random_value > 300 THEN  -- Reset to keep within range
            random_value <= 100;
        END IF;
    END PROCESS;
```

### Collisions
When collisions occur the game is over

```
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
```


### Scoring
If the bird passes through the pipeS successfully then an integer called 'Dis_num' increments by 1. Technically the score depends on if the pipes cross the middle instead of if the bird crosses the middle, since the bird is locked in on the Y axis and the pipes move against the X axis. The range is between x = 400 and x = 398 since it was not working properly for it to cross the legnth of a singluar pixel. This was because the pipes move by 2 pixels every clock cycle so a range had to be added to guarantee the score updates.  

```
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

```



## Images and/or videos
[![FlappyBird](./Documents/image.png)](https://www.youtube.com/shorts/GRCoJyo5vsY)


## Conclusion
The process of creating Flappy Bird out of Pong was interesting since some of our modifications had to be less conventional than usual due to the constraints of programming in VHDL. For example, the randomizer is not truly random but we came up with an innovative way to make it feel somewhat random for players who are trying this project out. Also Moving the pipes is not as simple as a basic transform, but it moves by 2 pixels per clock cycle since everything has to be synced up with the clock. There were many other little things that made programming Flappy Bird in this project very interesting, and arguably more interesting than using a high level language.  

John was responsible for the Major Functions within the code  
Joseph was responsible for Minor Functions like the randomizer and documentation  
Marco was responsible for delegation

Timelines are logged in Commit History over the last week, John had the board so all code was committed by him as he verified if our solutions worked. 

###  Difficulties

* Randomizing the Pipes -- Randomizer function which grabs a value from a range between 100 and 300 instead of being truly random (more details above)  
* Rendering the Pipes -- In the beginning everything BUT the pipe was colored in, this was fixed by flipping certain signs in the code which were overlooked and very difficult to spot  
* Keeping track of the Score -- The range is between x = 400 and x = 398 since it was not working properly for it to cross the legnth of a singluar pixel. This was because the pipes move by 2 pixels every clock cycle so a range had to be added to guarantee the score updates  
  


