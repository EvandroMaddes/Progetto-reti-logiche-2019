----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.02.2019 15:54:10
-- Design Name: 
-- Module Name: code - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL;
USE ieee.numeric_std.ALL;
entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_start : in std_logic;
    i_rst : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en  : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    --Viene creato un tipo per rappresentare i possibili stati del componente.
    type state_type is ( START, WAIT_SCANNING, READ_ADDRESS, SELECT_DATA, SCAN_ADDRESS_0, CALCULATE_DISTANCE, MIN_DISTANCE, DECREASE_INDEX, FIND_NEAREST, WAIT_SIGNAL, WRITE_OUT, DONE_HIGH, DONE_LOW);
    signal state : state_type; --Questa variabile tiene traccia tra le varie chiamate del processo dello stato in cui si trova il componente.
    
    signal    current_data : std_logic_vector(7 downto 0):="00000000";
    signal    current_address : std_logic_vector(15 downto 0):="0000000000010001";--inizializzo con la lettura dell'indirizzo 17
    signal    distanza_min : integer range 0 to 513 := 513;
    type int_array is array (7 downto 0) of integer range 513 downto 0 ;
    signal    distanze : int_array;
    signal    i,k: integer range 7 downto -1 :=7;
    signal     x_centroide, y_centroide, x_punto_valutare, y_punto_valutare : integer range -1 to 256 := -1;   



    

    
    begin
        process( i_rst, i_clk)     --il processo è eseguito ad commutazione del clock, la sincronizzazione sul fronte di salita è eseguita successivamente. 
                                                  --i_rst è stato inserito nella sensitivity list per permettere reset asincrono.


        begin
            if (i_rst = '1') then --Controllo segnale di reset -Asincrono-
                state <= START;
            elsif (i_rst = '0') then
            if (rising_edge(i_clk)) then --Sincronizzazione sul fronte di salita del clock.
                case state is
                    when START =>
                        if (i_start = '1') then --Attendi il segnale di start.
                           
                            k<=7;--Inizializzazione segnali.
                            x_centroide <= -1;
                            y_centroide <= -1;
                            x_punto_valutare <= -1;
                            y_punto_valutare <= -1;
                            distanza_min <= 513;
                            i <= 7;
                            o_address <= "0000000000000000";
                            o_done <= '0';
                            o_en <= '1';
                            o_we <= '0';
                            o_data <= "00000000";
                            current_address <= "0000000000010001"; --Inizializzazione segnali. Inizializzo con la lettura dell'indirizzo 17.
                            current_data <="00000000";
                            state <= READ_ADDRESS;
                        end if;
                
                    when READ_ADDRESS => 
                    --Permette la lettura dell'indirizzo settando i vari parametri.
                     if( conv_integer(current_address)>=0  )then
                   
                         o_en <= '1';
                         o_we <= '0';
                         o_address <= current_address;
                         state <= WAIT_SCANNING;
                         end if;

                   when WAIT_SCANNING =>
                    --Stato "vuoto" per attendere che la memoria invii i dati.
                        state <= SELECT_DATA;

                    
                    when SELECT_DATA =>--Lettura dei dati in arrivo dalla memoria.Il controllo dell'indirizzo corrente permette di stabilire quale variabile settare.
           
                        --Inizializzo la scansione dell'indirizzo 0.
                         if(conv_integer(current_address) = 0) then
                            current_data <= i_data(7 downto 0);
                            o_en <= '0';
                            state <= SCAN_ADDRESS_0;
                         end if;
                        
                        --Setto la coordinata X del centroide.
                        if( conv_integer(current_address)/= 17 and current_address(0)= '1') then
                            x_centroide <= conv_integer(i_data);
                            o_en <='0';
                          current_address<=current_address+"000000000000001";
                          state<=READ_ADDRESS;
                        end if;
                        
                        --Setto la coordinata Y del centroide.
                        if( conv_integer(current_address)/= 0 and conv_integer(current_address)/= 18 and current_address(0)= '0') then
                            y_centroide <= conv_integer(i_data);
                            o_en <= '0'; 
                            state <= CALCULATE_DISTANCE;
                        end if;
                        
                        --Setto X del punto da valutare.
                        if( conv_integer(current_address) = 17) then
                            x_punto_valutare <= conv_integer(i_data);
                            o_en<='0';
                             current_address <= current_address + "0000000000000001";
                            state <= READ_ADDRESS; 
                       end if;
                        
                        --Setto Y del punto da valutare.
                        if( conv_integer(current_address) = 18) then
                            y_punto_valutare <= conv_integer(i_data);
                            o_en <= '0';
                            current_address <= "0000000000000000";  --impongo la lettura dell'indirizzo 0.
                            state <= READ_ADDRESS; 
                        end if;
                        
                   
                        
                        
                    when SCAN_ADDRESS_0 =>
                    --Analizzo i singoli bit dell' indirizzo 0 per stabilire quali centroidi considerare.
                        if(current_data(i) = '1')then
                            current_address <=  std_logic_vector(to_unsigned(2*i+1,16));
                            state <= READ_ADDRESS;
                        elsif( current_data(i) = '0') then
                            state <= DECREASE_INDEX;
                        end if;
                     
                        
                    when CALCULATE_DISTANCE=>
                    --Calcola la distanza di ogni centroide da considerare rispetto al punto da valutare.
                     if(7>=i and i>=0)then
                        distanze(i)<= (abs(x_punto_valutare-x_centroide) + abs(y_punto_valutare-y_centroide));
                     end if;
                     state <= MIN_DISTANCE;
                         
                      when MIN_DISTANCE =>   
                       if(distanze(i)<distanza_min) then--Aggiorna il valore della distanza minima.
                          distanza_min <= distanze(i);  
                           end if;                      
                        state <= DECREASE_INDEX;          
           
                    
                    when DECREASE_INDEX =>
                    --Diminuisco il valore di i per continuare l'analisi dell'indirizzo 0.
                        if(i>0)then
                            i <= i-1;
                            state <= SCAN_ADDRESS_0;
                        elsif(0>=i) then
                            state <= FIND_NEAREST;
                        end if;

                     
                     when FIND_NEAREST=> 
                     --Confronta le distanze calcolate che sono pari alla distanza minima e riporta il risultato in current_data.
                     if(k>=0)and(7>=k)then

                        if(distanze(k) /= distanza_min) and (current_data(k)='1')then--Varia solo i bit a 1 poiche gli altri non sono da considerare. 
                            current_data(k) <= '0'; 
                        end if;

                        k<=k-1;
                        state<=FIND_NEAREST;
                        
                      elsif(0>k)or(k>7) then
                      state <= WAIT_SIGNAL;
                     end if;
                     
                    when WAIT_SIGNAL =>
                    --imposto i segnali per la scrittura in memoria.
                     o_en <= '1';
                     o_we <= '1';
                     state <= WRITE_OUT;
                     
                     when WRITE_OUT =>
                     --Scrivo il risultato in memoria.
                     o_address<="0000000000010011"; 
                     o_data <= current_data;
                     state<=DONE_HIGH;
                    
                    --Stati che alzano il segnale di fine per un ciclo di clock.
                    when DONE_HIGH =>
                         o_en <= '0';
                         o_done <= '1';
                         state <= DONE_LOW;
                         
                    when DONE_LOW =>
                        o_done <= '0';
                        state <= START; --Riporta il componente allo stato iniziale pronto per eseguire un'altra operazione.        
                end case;
            end if;--if rising clk
           end if;--if del reset = '0'
        end process;
end Behavioral;
