-- old method
with
divlist as(
select A.Num as Numdiv, B.Num as divisore
  from  (select seq4()+1 as Num from table(generator(rowcount => 1e6)) where  Num < 10e6 )A
  left join  (select seq4()+1 as Num from table(generator(rowcount => 1e6)) where  Num <= sqrt(10e6)) B
    on B.Num < A.Num and mod(A.Num, B.Num) = 0 and b.num > 1
) -- list of dividend, inefficient but ne need just a small number of prime (all primes < 10^6)
  -- it is possible to greatly improve using for example the fact that primes is a subset of {x; 2 | 6 n +- 1}
,
primes as (
   select  Numdiv as Num from divlist where divisore is null and Num > 1 
)
 select * from primes;
-- 10.17s, 78,498


-- utility: get primes
set maxPrime = 1e7;
with
list1 as(
   select (seq4()+1)*6 +1 as Num from table(generator(rowcount => $maxPrime)) where Num <= $maxPrime
     union all
   select (seq4()+1)*6 -1 as Num from table(generator(rowcount => $maxPrime)) where Num <= $maxPrime
     union all 
   select 2 as Num
     union all
   select 3 as Num
),
divlist as(
select A.Num as Numdiv, B.Num as divisore
  from  (select Num from list1 )A
  left join  (select Num from list1 where  Num <= sqrt($maxPrime)) B
    on B.Num < A.Num and mod(A.Num, B.Num) = 0 and b.num > 1
) ,
primes as (
   select  Numdiv as Num from divlist where divisore is null and Num > 1 
)
 select * from primes order by 1 ;
-- 11.23 sec 664579 (confirmed by google)

-- fibonacci
WITH RECURSIVE fib(f1, f2, lev) AS ( 
    SELECT 0, 1, 1 
    UNION ALL
    SELECT f2, (f1+f2), lev +1 FROM fib where lev < 99) 
SELECT lev, f1 FROM fib limit 99;

-- example of tab literal
select * from 
    ( values (1, 'a'), 
             (2, 'b'), 
             (3, 'c')
    ) as taba (cola, colb);


------------------------------------------------------------------------------------------------------------
----Euler 11
/*
in the 20×20 grid below, four numbers along a diagonal line have been marked in red.

08 02 22 97 38 15 00 40 00 75 04 05 07 78 52 12 50 77 91 08
49 49 99 40 17 81 18 57 60 87 17 40 98 43 69 48 04 56 62 00
81 49 31 73 55 79 14 29 93 71 40 67 53 88 30 03 49 13 36 65
52 70 95 23 04 60 11 42 69 24 68 56 01 32 56 71 37 02 36 91
22 31 16 71 51 67 63 89 41 92 36 54 22 40 40 28 66 33 13 80
24 47 32 60 99 03 45 02 44 75 33 53 78 36 84 20 35 17 12 50
32 98 81 28 64 23 67 10 26 38 40 67 59 54 70 66 18 38 64 70
67 26 20 68 02 62 12 20 95 63 94 39 63 08 40 91 66 49 94 21
24 55 58 05 66 73 99 26 97 17 78 78 96 83 14 88 34 89 63 72
21 36 23 09 75 00 76 44 20 45 35 14 00 61 33 97 34 31 33 95
78 17 53 28 22 75 31 67 15 94 03 80 04 62 16 14 09 53 56 92
16 39 05 42 96 35 31 47 55 58 88 24 00 17 54 24 36 29 85 57
86 56 00 48 35 71 89 07 05 44 44 37 44 60 21 58 51 54 17 58
19 80 81 68 05 94 47 69 28 73 92 13 86 52 17 77 04 89 55 40
04 52 08 83 97 35 99 16 07 97 57 32 16 26 26 79 33 27 98 66
88 36 68 87 57 62 20 72 03 46 33 67 46 55 12 32 63 93 53 69
04 42 16 73 38 25 39 11 24 94 72 18 08 46 29 32 40 62 76 36
20 69 36 41 72 30 23 88 34 62 99 69 82 67 59 85 74 04 36 16
20 73 35 29 78 31 90 01 74 31 49 71 48 86 81 16 23 57 05 54
01 70 54 71 83 51 54 69 16 92 33 48 61 43 52 01 89 19 67 48

The product of these numbers is 26 × 63 × 78 × 14 = 1788696.

What is the greatest product of four adjacent numbers in the same direction (up, down, left, right, or diagonally) in the 20×20 grid?
*/
use database util_db;
use schema public;
create or replace temporary table t1 (v varchar);
create or replace temporary table t2 (r integer, c integer, v integer);

insert into t1
with bigstring as (select translate(
  '08 02 22 97 38 15 00 40 00 75 04 05 07 78 52 12 50 77 91 08
49 49 99 40 17 81 18 57 60 87 17 40 98 43 69 48 04 56 62 00
81 49 31 73 55 79 14 29 93 71 40 67 53 88 30 03 49 13 36 65
52 70 95 23 04 60 11 42 69 24 68 56 01 32 56 71 37 02 36 91
22 31 16 71 51 67 63 89 41 92 36 54 22 40 40 28 66 33 13 80
24 47 32 60 99 03 45 02 44 75 33 53 78 36 84 20 35 17 12 50
32 98 81 28 64 23 67 10 26 38 40 67 59 54 70 66 18 38 64 70
67 26 20 68 02 62 12 20 95 63 94 39 63 08 40 91 66 49 94 21
24 55 58 05 66 73 99 26 97 17 78 78 96 83 14 88 34 89 63 72
21 36 23 09 75 00 76 44 20 45 35 14 00 61 33 97 34 31 33 95
78 17 53 28 22 75 31 67 15 94 03 80 04 62 16 14 09 53 56 92
16 39 05 42 96 35 31 47 55 58 88 24 00 17 54 24 36 29 85 57
86 56 00 48 35 71 89 07 05 44 44 37 44 60 21 58 51 54 17 58
19 80 81 68 05 94 47 69 28 73 92 13 86 52 17 77 04 89 55 40
04 52 08 83 97 35 99 16 07 97 57 32 16 26 26 79 33 27 98 66
88 36 68 87 57 62 20 72 03 46 33 67 46 55 12 32 63 93 53 69
04 42 16 73 38 25 39 11 24 94 72 18 08 46 29 32 40 62 76 36
20 69 36 41 72 30 23 88 34 62 99 69 82 67 59 85 74 04 36 16
20 73 35 29 78 31 90 01 74 31 49 71 48 86 81 16 23 57 05 54
01 70 54 71 83 51 54 69 16 92 33 48 61 43 52 01 89 19 67 48', '0123456789
', '0123456789.') as str)
select t.value from table(split_to_table((select str from bigstring), '.')) t
;
insert into t2
select seq as r, index as c, cast(value as integer) as v from
(select * from t1, lateral split_to_table(t1.v, ' '));

-- it is enough to check only one direction: down, right, diag left-to-right, diag-right to-left

-- left
select max(prod) from
(
    select t2.r, t2.c, t2.v, ifnull(d1.v,1), ifnull(d2.v,1), ifnull(d3.v,1),  t2.v * ifnull(d1.v,1) * ifnull(d2.v,1) * ifnull(d3.v,1) as prod
    from t2
      left join t2 d1 on d1.r = t2.r and d1.c = (t2.c +1) 
      left join t2 d2 on d2.r = t2.r and d2.c = (t2.c +2)
      left join t2 d3 on d3.r = t2.r and d3.c = (t2.c +3) 
    union all
    
    -- down
    select t2.r, t2.c, t2.v, ifnull(d1.v,1), ifnull(d2.v,1), ifnull(d3.v,1),  t2.v * ifnull(d1.v,1) * ifnull(d2.v,1) * ifnull(d3.v,1) as prod
    from t2
      left join t2 d1 on d1.r = (t2.r + 1) and d1.c = t2.c  
      left join t2 d2 on d2.r = (t2.r + 2) and d2.c = t2.c 
      left join t2 d3 on d3.r = (t2.r + 3) and d3.c = t2.c  
    union all
      
    -- diag 1
    select t2.r, t2.c, t2.v, ifnull(d1.v,1), ifnull(d2.v,1), ifnull(d3.v,1),  t2.v * ifnull(d1.v,1) * ifnull(d2.v,1) * ifnull(d3.v,1) as prod
    from t2
      left join t2 d1 on d1.r = (t2.r + 1) and d1.c = (t2.c +1) 
      left join t2 d2 on d2.r = (t2.r + 2) and d2.c = (t2.c +2)
      left join t2 d3 on d3.r = (t2.r + 3) and d3.c = (t2.c +3)
    union all
  
    -- diag 2
    select t2.r, t2.c, t2.v, ifnull(d1.v,1), ifnull(d2.v,1), ifnull(d3.v,1),  t2.v * ifnull(d1.v,1) * ifnull(d2.v,1) * ifnull(d3.v,1) as prod
    from t2
      left join t2 d1 on d1.r = (t2.r + 1) and d1.c = (t2.c -1) 
      left join t2 d2 on d2.r = (t2.r + 2) and d2.c = (t2.c -2)
      left join t2 d3 on d3.r = (t2.r + 3) and d3.c = (t2.c -3)
);


------------------------------------------------------------------------------------------------------------
----Euler 12
/*
The sequence of triangle numbers is generated by adding the natural numbers. So the 7th triangle number would be 1 + 2 + 3 + 4 + 5 + 6 + 7 = 28. The first ten terms would be:

1, 3, 6, 10, 15, 21, 28, 36, 45, 55, ...

Let us list the factors of the first seven triangle numbers:

 1: 1
 3: 1,3
 6: 1,2,3,6
10: 1,2,5,10
15: 1,3,5,15
21: 1,3,7,21
28: 1,2,4,7,14,28
We can see that 28 is the first triangle number to have over five divisors.

What is the value of the first triangle number to have over five hundred divisors?
*/
-- generator: select sum(seq4()+1) over (order by seq4()) as Num from table(generator(rowcount => 1e5)) ; 
-- we could use the fact that given the prime decomposition p1^n1 + p2^n2 + .. + pn^nn, the divisors are (n1+1)*(n2+1)*..*(nn+1) (Wikipedia)


with tris as (
 select sum(seq4()+1) over (order by seq4()) as Num from table(generator(rowcount => 2e4)) 
  )-- generate triangolar number
, 
divlist as(
select A.Num as Numdiv, B.Num as divisore
  from  (select seq4()+1 as Num from table(generator(rowcount => 1e6)) where  Num < (select max(Num) from tris)) A
  left join  (select seq4()+1 as Num from table(generator(rowcount => 1e6)) where  Num <= sqrt((select max(Num) from tris))) B
    on B.Num < A.Num and mod(A.Num, B.Num) = 0 and b.num > 1
) -- list of dividend, inefficient but ne need just a small number of prime (all primes < 10^6)
  -- it is possible to greatly improve using for example the fact that primes is a subset of {x; 2 | 6 n +- 1}
,
primes as (
   select  Numdiv as Num from divlist where divisore is null and Num > 1 and Num <= sqrt((select max(Num) from tris))
),
expons as (
select seq4()+1 as Num from table(generator(rowcount => 1e6)) where  Num < (select trunc(log(2,(select max(Num) from tris))) +1)-- max needed exponent of 2
)

select t as Triangular, exp(sum(logff)) as NumDivisor
from(
    select t,p, ln(max(e) +1) as logff
    from
    (
        select  tri.Num as t,     -- triangular number
                pri.Num as p,     -- prime divisor
                exo.num as e ,    -- prime exponent
                t/pow(p,e) as f
         from tris     tri
           join expons exo
           join primes pri
        where
        mod(t,pow(p,e)) = 0
    ) group by t,p
)
group by 1
having NumDivisor >= 500
order by 1
;
-- 76576500

------------------------------------------------------------------------------------------------------------
----Euler 13
/*
Work out the first ten digits of the sum of the following one-hundred 50-digit numbers.

37107287533902102798797998220837590246510135740250
46376937677490009712648124896970078050417018260538
74324986199524741059474233309513058123726617309629
91942213363574161572522430563301811072406154908250
23067588207539346171171980310421047513778063246676
89261670696623633820136378418383684178734361726757
28112879812849979408065481931592621691275889832738
44274228917432520321923589422876796487670272189318
47451445736001306439091167216856844588711603153276
70386486105843025439939619828917593665686757934951
62176457141856560629502157223196586755079324193331
64906352462741904929101432445813822663347944758178
92575867718337217661963751590579239728245598838407
58203565325359399008402633568948830189458628227828
80181199384826282014278194139940567587151170094390
35398664372827112653829987240784473053190104293586
86515506006295864861532075273371959191420517255829
71693888707715466499115593487603532921714970056938
54370070576826684624621495650076471787294438377604
53282654108756828443191190634694037855217779295145
36123272525000296071075082563815656710885258350721
45876576172410976447339110607218265236877223636045
17423706905851860660448207621209813287860733969412
81142660418086830619328460811191061556940512689692
51934325451728388641918047049293215058642563049483
62467221648435076201727918039944693004732956340691
15732444386908125794514089057706229429197107928209
55037687525678773091862540744969844508330393682126
18336384825330154686196124348767681297534375946515
80386287592878490201521685554828717201219257766954
78182833757993103614740356856449095527097864797581
16726320100436897842553539920931837441497806860984
48403098129077791799088218795327364475675590848030
87086987551392711854517078544161852424320693150332
59959406895756536782107074926966537676326235447210
69793950679652694742597709739166693763042633987085
41052684708299085211399427365734116182760315001271
65378607361501080857009149939512557028198746004375
35829035317434717326932123578154982629742552737307
94953759765105305946966067683156574377167401875275
88902802571733229619176668713819931811048770190271
25267680276078003013678680992525463401061632866526
36270218540497705585629946580636237993140746255962
24074486908231174977792365466257246923322810917141
91430288197103288597806669760892938638285025333403
34413065578016127815921815005561868836468420090470
23053081172816430487623791969842487255036638784583
11487696932154902810424020138335124462181441773470
63783299490636259666498587618221225225512486764533
67720186971698544312419572409913959008952310058822
95548255300263520781532296796249481641953868218774
76085327132285723110424803456124867697064507995236
37774242535411291684276865538926205024910326572967
23701913275725675285653248258265463092207058596522
29798860272258331913126375147341994889534765745501
18495701454879288984856827726077713721403798879715
38298203783031473527721580348144513491373226651381
34829543829199918180278916522431027392251122869539
40957953066405232632538044100059654939159879593635
29746152185502371307642255121183693803580388584903
41698116222072977186158236678424689157993532961922
62467957194401269043877107275048102390895523597457
23189706772547915061505504953922979530901129967519
86188088225875314529584099251203829009407770775672
11306739708304724483816533873502340845647058077308
82959174767140363198008187129011875491310547126581
97623331044818386269515456334926366572897563400500
42846280183517070527831839425882145521227251250327
55121603546981200581762165212827652751691296897789
32238195734329339946437501907836945765883352399886
75506164965184775180738168837861091527357929701337
62177842752192623401942399639168044983993173312731
32924185707147349566916674687634660915035914677504
99518671430235219628894890102423325116913619626622
73267460800591547471830798392868535206946944540724
76841822524674417161514036427982273348055556214818
97142617910342598647204516893989422179826088076852
87783646182799346313767754307809363333018982642090
10848802521674670883215120185883543223812876952786
71329612474782464538636993009049310363619763878039
62184073572399794223406235393808339651327408011116
66627891981488087797941876876144230030984490851411
60661826293682836764744779239180335110989069790714
85786944089552990653640447425576083659976645795096
66024396409905389607120198219976047599490197230297
64913982680032973156037120041377903785566085089252
16730939319872750275468906903707539413042652315011
94809377245048795150954100921645863754710598436791
78639167021187492431995700641917969777599028300699
15368713711936614952811305876380278410754449733078
40789923115535562561142322423255033685442488917353
44889911501440648020369068063960672322193204149535
41503128880339536053299340368006977710650566631954
81234880673210146739058568557934581403627822703280
82616570773948327592232845941706525094512325230608
22918802058777319719839450180888072429661980811197
77158542502016545090413245809786882778948721859617
72107838435069186155435662884062257473692284509516
20849603980134001723930671666823555245252804609722
53503534226472524250874054075591789781264330331690
*/

with bigstring as (select translate(
'37107287533902102798797998220837590246510135740250
46376937677490009712648124896970078050417018260538
74324986199524741059474233309513058123726617309629
91942213363574161572522430563301811072406154908250
23067588207539346171171980310421047513778063246676
89261670696623633820136378418383684178734361726757
28112879812849979408065481931592621691275889832738
44274228917432520321923589422876796487670272189318
47451445736001306439091167216856844588711603153276
70386486105843025439939619828917593665686757934951
62176457141856560629502157223196586755079324193331
64906352462741904929101432445813822663347944758178
92575867718337217661963751590579239728245598838407
58203565325359399008402633568948830189458628227828
80181199384826282014278194139940567587151170094390
35398664372827112653829987240784473053190104293586
86515506006295864861532075273371959191420517255829
71693888707715466499115593487603532921714970056938
54370070576826684624621495650076471787294438377604
53282654108756828443191190634694037855217779295145
36123272525000296071075082563815656710885258350721
45876576172410976447339110607218265236877223636045
17423706905851860660448207621209813287860733969412
81142660418086830619328460811191061556940512689692
51934325451728388641918047049293215058642563049483
62467221648435076201727918039944693004732956340691
15732444386908125794514089057706229429197107928209
55037687525678773091862540744969844508330393682126
18336384825330154686196124348767681297534375946515
80386287592878490201521685554828717201219257766954
78182833757993103614740356856449095527097864797581
16726320100436897842553539920931837441497806860984
48403098129077791799088218795327364475675590848030
87086987551392711854517078544161852424320693150332
59959406895756536782107074926966537676326235447210
69793950679652694742597709739166693763042633987085
41052684708299085211399427365734116182760315001271
65378607361501080857009149939512557028198746004375
35829035317434717326932123578154982629742552737307
94953759765105305946966067683156574377167401875275
88902802571733229619176668713819931811048770190271
25267680276078003013678680992525463401061632866526
36270218540497705585629946580636237993140746255962
24074486908231174977792365466257246923322810917141
91430288197103288597806669760892938638285025333403
34413065578016127815921815005561868836468420090470
23053081172816430487623791969842487255036638784583
11487696932154902810424020138335124462181441773470
63783299490636259666498587618221225225512486764533
67720186971698544312419572409913959008952310058822
95548255300263520781532296796249481641953868218774
76085327132285723110424803456124867697064507995236
37774242535411291684276865538926205024910326572967
23701913275725675285653248258265463092207058596522
29798860272258331913126375147341994889534765745501
18495701454879288984856827726077713721403798879715
38298203783031473527721580348144513491373226651381
34829543829199918180278916522431027392251122869539
40957953066405232632538044100059654939159879593635
29746152185502371307642255121183693803580388584903
41698116222072977186158236678424689157993532961922
62467957194401269043877107275048102390895523597457
23189706772547915061505504953922979530901129967519
86188088225875314529584099251203829009407770775672
11306739708304724483816533873502340845647058077308
82959174767140363198008187129011875491310547126581
97623331044818386269515456334926366572897563400500
42846280183517070527831839425882145521227251250327
55121603546981200581762165212827652751691296897789
32238195734329339946437501907836945765883352399886
75506164965184775180738168837861091527357929701337
62177842752192623401942399639168044983993173312731
32924185707147349566916674687634660915035914677504
99518671430235219628894890102423325116913619626622
73267460800591547471830798392868535206946944540724
76841822524674417161514036427982273348055556214818
97142617910342598647204516893989422179826088076852
87783646182799346313767754307809363333018982642090
10848802521674670883215120185883543223812876952786
71329612474782464538636993009049310363619763878039
62184073572399794223406235393808339651327408011116
66627891981488087797941876876144230030984490851411
60661826293682836764744779239180335110989069790714
85786944089552990653640447425576083659976645795096
66024396409905389607120198219976047599490197230297
64913982680032973156037120041377903785566085089252
16730939319872750275468906903707539413042652315011
94809377245048795150954100921645863754710598436791
78639167021187492431995700641917969777599028300699
15368713711936614952811305876380278410754449733078
40789923115535562561142322423255033685442488917353
44889911501440648020369068063960672322193204149535
41503128880339536053299340368006977710650566631954
81234880673210146739058568557934581403627822703280
82616570773948327592232845941706525094512325230608
22918802058777319719839450180888072429661980811197
77158542502016545090413245809786882778948721859617
72107838435069186155435662884062257473692284509516
20849603980134001723930671666823555245252804609722
53503534226472524250874054075591789781264330331690'
  , 
  '0123456789
', '0123456789.') as str)
select left(to_varchar(sum(cast(t.value as double)), '99999999999EE'),11) as Result 
--select t.value
from table(split_to_table((select str from bigstring), '.')) t
; --5537376230


------------------------------------------------------------------------------------------------------------
----Euler 14
/*
The following iterative sequence is defined for the set of positive integers:

n → n/2 (n is even)
n → 3n + 1 (n is odd)

Using the rule above and starting with 13, we generate the following sequence:
13 → 40 → 20 → 10 → 5 → 16 → 8 → 4 → 2 → 1
It can be seen that this sequence (starting at 13 and finishing at 1) contains 10 terms. Although it has not been proved yet (Collatz Problem), 
  it is thought that all starting numbers finish at 1.
Which starting number, under one million, produces the longest chain?
NOTE: Once the chain starts the terms are allowed to go above one million.
*/


// a recursive solution is elegant but not possible in snowflake bcs there is a low max recursion of 100
create or replace temporary table collats (n integer) as select seq4()+1 as n from table(generator(rowcount => 1e6)) ;

// a recursive solution is elegant but not possible in snowflake bcs there is a low max recursion of 100
//create or replace temporary table collats (n integer) as select seq4()+1 as n from table(generator(rowcount => 1e6)) ;

-- use sql_lite
create  table collats as select * from (
WITH RECURSIVE gen(n) AS (
  SELECT 1
  UNION ALL
  SELECT n+1 FROM gen
   WHERE n+1 <= 1000000
) select * from gen
);


with 
recursive CollatsNumbers (RecursionLevel, CollatsNumber, NextCollats) 
AS (
   -- Anchor member definition
   SELECT  0  AS RecursionLevel,
           n  AS CollatsNumber ,
           n  AS NextCollats from collats
   UNION ALL
   -- Recursive member definition
   SELECT  a.RecursionLevel + 1 AS RecursionLevel,
           CollatsNumber,
           case when mod(a.NextCollats, 2) = 0 then   a.NextCollats / 2 else a.NextCollats*3+1 end AS NextCollats
   FROM CollatsNumbers a 
   WHERE  NextCollats != 1 and RecursionLevel <800
)
SELECT CollatsNumber, RecursionLevel,  NextCollats
FROM CollatsNumbers 
where 
(RecursionLevel <= 800 and NextCollats  = 1) or  (RecursionLevel = 800  and NextCollats != 1)     
order by  recursionLevel desc limit 10 
;
/*
837799|524|1
626331|508|1
939497|506|1
704623|503|1
910107|475|1
927003|475|1
511935|469|1
767903|467|1
796095|467|1
970599|457|1
*/




------------------------------------------------------------------------------------------------------------
----Euler 15
/*
Starting in the top left corner of a 2×2 grid, and only being able to move to the right and down, there are exactly 6 routes to the bottom right corner.

How many such routes are there through a 20×20 grid?
*/
-- this is equivalent of finding the RRDRD...RD string of lenght 40 having 20 R and 20D, i.e. choose(40,20)

set n = 40;
set k = 20;
select round(exp(sum(ln(n)))/factorial($k),0) from (select seq4()+1 as n from table(generator(rowcount => 1e6))) where n>$k and n<=$n ;
-- 137846528820

------------------------------------------------------------------------------------------------------------
----Euler 16
--2^15 = 32768 and the sum of its digits is 3 + 2 + 7 + 6 + 8 = 26.
--What is the sum of the digits of the number 2^1000?

-- it is a 333 digit numbers, it cannot be used as a calc
-- algorithm: (n,k) n iteration of the kth digit 
-- (n, k) = ((n-1,k) * 2 + ((n-1,k-1)* 2 div 10) mod 10

-- temporarily solved with excel
-- it is solvable in sqllite where thre are no limiations in recursion
-- method is the same as problem 20 (at the end of this file)

------------------------------------------------------------------------------------------------------------
----Euler 17
/*
If the numbers 1 to 5 are written out in words: one, two, three, four, five, then there are 3 + 3 + 5 + 4 + 4 = 19 letters used in total.

If all the numbers from 1 to 1000 (one thousand) inclusive were written out in words, how many letters would be used?

NOTE: Do not count spaces or hyphens. For example, 342 (three hundred and forty-two) contains 23 letters and 115 (one hundred and fifteen) contains 20 letters. The use of "and" when writing out numbers is in compliance with British usage.
*/
-- not much interesting, will return on it

with twenty as(
    select 1  as n, 'one'       as nstr union all
    select 2  as n, 'two'       as nstr union all
    select 3  as n, 'three'     as nstr union all
    select 4  as n, 'four'      as nstr union all
    select 5  as n, 'five'      as nstr union all
    select 6  as n, 'six'       as nstr union all
    select 7  as n, 'seven'     as nstr union all
    select 8  as n, 'eight'     as nstr union all
    select 9  as n, 'nine'      as nstr union all
    select 10 as n, 'ten'       as nstr union all
    select 11 as n, 'eleven'    as nstr union all
    select 12 as n, 'twelve'    as nstr union all
    select 13 as n, 'thirteen'  as nstr union all
    select 14 as n, 'fourteen'  as nstr union all
    select 15 as n, 'fifteen'   as nstr union all
    select 16 as n, 'sixteen'   as nstr union all
    select 17 as n, 'seventeen' as nstr union all
    select 18 as n, 'eighteen'  as nstr union all
    select 19 as n, 'nineteen'  as nstr 
), decads as (
    select 2 as n, 'twenty'  as nstr union all
    select 3 as n, 'thirty'  as nstr union all
    select 4 as n, 'forty'   as nstr union all
    select 5 as n, 'fifty'   as nstr union all
    select 6 as n, 'sixty'   as nstr union all
    select 7 as n, 'seventy' as nstr union all
    select 8 as n, 'eighty'  as nstr union all
    select 9 as n, 'ninety'  as nstr 
), 
seq as (
    select seq4()+1 as Num from table(generator(rowcount => 1e6)) where  Num < 10e6 
)
select sum(len) from (
select 
    s.Num, 
--    mod(s.Num,10)              as unit, 
--    mod(s.Num,100)             as undec, 
--    trunc(mod(s.Num,100)/10)   as dec,
--    trunc(mod(s.Num,1000)/100) as hun,
    case when s.Num <20  then t.nstr 
         when s.Num <100 and mod(s.Num,10) = 0 then d.nstr
         when s.Num <100  then d.nstr || '-' || t2.nstr
         when s.Num <1000 and mod(s.Num,100) = 0 then t3.nstr  || ' ' || 'hundred'
         when s.Num <1000 and mod(s.Num,100)< 20 then t3.nstr  || ' ' || 'hundred' || ' and ' ||  t.nstr 
         when s.Num <1000 and mod(s.Num,10) = 0 then t3.nstr  || ' ' || 'hundred' || ' and ' ||  d.nstr 
         when s.Num <1000 then t3.nstr  || ' ' || 'hundred' || ' and ' ||  d.nstr || '-' || t2.nstr
         else 'one thousand'
    end as ss,
    length(replace(replace(ss, ' ', ''), '-', '')) as len
from seq s 
  left join twenty t  on mod(s.Num,100) = t.n
  left join decads d  on trunc(mod(s.Num,100)/10) = d.n
  left join twenty t2 on mod(s.Num,10) = t2.n
  left join twenty t3 on trunc(mod(s.Num,1000)/100) = t3.n

where  s.Num <=1000   
--order by s.Num desc 
    );


------------------------------------------------------------------------------------------------------------
----Euler 18
/*
By starting at the top of the triangle below and moving to adjacent numbers on the row below, the maximum total from top to bottom is 23.

3
7 4
2 4 6
8 5 9 3

That is, 3 + 7 + 4 + 9 = 23.

Find the maximum total from top to bottom of the triangle below:

              75
             95 64
            17 47 82
           18 35 87 10
          20 04 82 47 65
         19 01 23 75 03 34
        88 02 77 73 07 63 67
       99 65 04 28 06 16 70 92
      41 41 26 56 83 40 80 70 33
     41 48 72 33 47 32 37 16 94 29
    53 71 44 65 25 43 91 52 97 51 14
   70 11 33 28 77 73 17 78 39 68 17 57
  91 71 52 38 17 14 91 43 58 50 27 29 48
 63 66 04 68 89 53 67 30 73 16 69 87 40 31
04 62 98 27 23 09 70 98 73 93 38 53 60 04 23

NOTE: As there are only 16384 routes, it is possible to solve this problem by trying every route. However, Problem 67, is the same challenge with a triangle containing one-hundred rows; it cannot be solved by brute force, and requires a clever method! ;o)
*/

use schema public;

create temporary table t1 as 
with bigstring as (select translate(
'75
95 64
17 47 82
18 35 87 10
20 04 82 47 65
19 01 23 75 03 34
88 02 77 73 07 63 67
99 65 04 28 06 16 70 92
41 41 26 56 83 40 80 70 33
41 48 72 33 47 32 37 16 94 29
53 71 44 65 25 43 91 52 97 51 14
70 11 33 28 77 73 17 78 39 68 17 57
91 71 52 38 17 14 91 43 58 50 27 29 48
63 66 04 68 89 53 67 30 73 16 69 87 40 31
04 62 98 27 23 09 70 98 73 93 38 53 60 04 23'
  , 
  '0123456789
', '0123456789.') as str),
t1 as (
  select value as val from  table(split_to_table((select str from bigstring), '.'))
)
select seq as r, index as c, cast(value as integer) as v from t1, lateral split_to_table(t1.val, ' ')
;

-- check the loaded rows
select * from t1 order by r, c;


-- let's try another route
-- the real deal
with recursive path (level, r, c, v, sumv, l ) as
(
select 1, 1, 1, anchor.v, anchor.v, to_varchar(anchor.v)
from t1 anchor where anchor.r = 1 and anchor.c = 1
union all
select
    p.level+1, 
    t1.r, 
    t1.c, 
    t1.v,
    p.sumv + t1.v,
    p.l  || '->'  || to_varchar(t1.v) --debug
from path p
   join t1 t1 on t1.r = p.r+1 and t1.c in( p.c, p.c+1)  -- get both the path
    where 1=1
) 
select level, r, c, v, sumv, l from
(select *, count(*) over (partition by r,c order by sumv desc) as hold from path ) 
where hold = 1  and r=15 order by sumv desc;
  -- 447 the min
-- 1074 the max


-------------------------------------------------------------------------------------------------
-- this is not the best algorithm, At every step I should purge the path which does not contribute
-- i tried but there are seriuous limitation in the use of CTE
-- (i know i could use window functions in the result query, but this means i still have to caldulate all the path)

-- for example:
-- try with windows function
select * from (select *,
count(*) over (partition by r,c order by sumv desc) as hold
from t2 )
group by 1,2,3,4,5,6,7;
having hold = 1;
-- Window functions are not allowed in a CTEs recursive term.

-- try with group by (list will not be correct, but is there just for debugging)
select level, r, c, max(v), max(sumv), max(l)
from t2
group by level, r, c;
-- Aggregate functions are not allowed in a CTEs recursive term.

drop table t1;
drop table t2;

------------------------------------------------------------------------------------------------------------
----Euler 19
/*
You are given the following information, but you may prefer to do some research for yourself.

1 Jan 1900 was a Monday.
Thirty days has September,
April, June and November.
All the rest have thirty-one,
Saving February alone,
Which has twenty-eight, rain or shine.
And on leap years, twenty-nine.
A leap year occurs on any year evenly divisible by 4, but not on a century unless it is divisible by 400.
How many Sundays fell on the first of the month during the twentieth century (1 Jan 1901 to 31 Dec 2000)?
*/

-- this should be easy 

select 
count(*)
from
(select
    Num,
    DATEADD(day, Num, '1901-01-01'::date)::date   as SQL_DATE,
    DATE_PART(dw_iso, SQL_DATE)                                  as DOW,
    DAY(SQL_DATE)                                                as day_Of_Month
from (select seq4() as Num from table(generator(rowcount => 1e6))   )
  where 
  sql_date >= cast('1901-01-01' as date) and sql_date <= cast('2000-12-31' as DATE)
  and DATE_PART(dw_iso, SQL_DATE) = 7 and day_Of_Month = 1
 );


------------------------------------------------------------------------------------------------------------
----Euler 20
/*
n! means n × (n − 1) × ... × 3 × 2 × 1

For example, 10! = 10 × 9 × ... × 3 × 2 × 1 = 3628800,
and the sum of the digits in the number 10! is 3 + 6 + 2 + 8 + 8 + 0 + 0 = 27.

Find the sum of the digits in the number 100!
*/
-- due to the limitations of recursion in snowflake i have to start from 2!

with recursive dd (n , n16, n15, n14, n13, n12, n11, n10, n9, n8, n7, n6, n5, n4, n3, n2, n1 ) as
(
select 
    cast(2 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int) ,
    cast(0 as int), 
    cast(0 as int), 
    cast(0 as int), 
    cast(0 as int), 
    cast(0 as int), 
    cast(0 as int), 
    cast(2 as int)
union all
select n+1, 
    mod(n16*(n+1)+ trunc(n15*(n+1)/10000000000), 10000000000),
    mod(n15*(n+1)+ trunc(n14*(n+1)/10000000000), 10000000000),
    mod(n14*(n+1)+ trunc(n13*(n+1)/10000000000), 10000000000),
    mod(n13*(n+1)+ trunc(n12*(n+1)/10000000000), 10000000000),
    mod(n12*(n+1)+ trunc(n11*(n+1)/10000000000), 10000000000),
    mod(n11*(n+1)+ trunc(n10*(n+1)/10000000000), 10000000000),
    mod(n10*(n+1)+ trunc(n9 *(n+1)/10000000000), 10000000000),
    mod(n9* (n+1)+ trunc(n8 *(n+1)/10000000000), 10000000000),
    mod(n8* (n+1)+ trunc(n7 *(n+1)/10000000000), 10000000000),
    mod(n7* (n+1)+ trunc(n6 *(n+1)/10000000000), 10000000000),
    mod(n6* (n+1)+ trunc(n5 *(n+1)/10000000000), 10000000000),
    mod(n5* (n+1)+ trunc(n4 *(n+1)/10000000000), 10000000000),
    mod(n4* (n+1)+ trunc(n3 *(n+1)/10000000000), 10000000000),
    mod(n3* (n+1)+ trunc(n2 *(n+1)/10000000000), 10000000000),
    mod(n2* (n+1)+ trunc(n1 *(n+1)/10000000000), 10000000000),
    mod(n1* (n+1),10000000000) 

    from dd
where n < 100
) select 
n,
to_varchar(n16) || 
to_varchar(n15, '0000000000') || 
to_varchar(n14, '0000000000') || 
to_varchar(n13, '0000000000') || 
to_varchar(n12, '0000000000') || 
to_varchar(n11, '0000000000') || 
to_varchar(n10, '0000000000') || 
to_varchar(n9, '0000000000') || 
to_varchar(n8, '0000000000') || 
to_varchar(n7, '0000000000') || 
to_varchar(n6, '0000000000') || 
to_varchar(n5, '0000000000') || 
to_varchar(n4, '0000000000') || 
to_varchar(n3, '0000000000') || 
to_varchar(n2, '0000000000') || 
to_varchar(n1, '0000000000') as N_fatt,
regexp_count(N_fatt, '1')+
regexp_count(N_fatt, '2')*2+
regexp_count(N_fatt, '3')*3+
regexp_count(N_fatt, '4')*4+
regexp_count(N_fatt, '5')*5+
regexp_count(N_fatt, '6')*6+
regexp_count(N_fatt, '7')*7+
regexp_count(N_fatt, '8')*8+
regexp_count(N_fatt, '9')*9 as SumChar
from dd  ;

