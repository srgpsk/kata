/*
 Note: The create_user_batch_v7_joins code below is not dynamic and ignores @max_users

 Run as:
 mysql -vvv < test_insert.sql | \
 grep -iA 5 -e 'call create_user_batch'| \
 grep -E -e 'create_user_batch[a-z0-9_]+' -e '[0-9\.]+? sec'

 Or with docker:
 docker run -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=true -d --rm --name mariadb -p 3306:3306 -v $(pwd)/optimized.cnf:/etc/my.cnf mariadb:10.10.3-jammy

 docker exec -i mariadb mysql -vvv < test_insert.sql | \
 grep -iA 5 -e 'call create_user_batch' | \
 grep -E -e 'create_user_batch[a-z0-9_]+' -e '[0-9\.]+? sec'

 And/Or with nice table output:
 tput setaf 2; docker exec -i mariadb mysql -vvv  < test_insert.sql | grep -iA 5 -e 'call create_user_batch' | \
 grep -oE -e 'create_user_batch[a-z0-9_]+' -e '[0-9]+ rows' -e 'affected (.+?)' | \
 sed -e 's/create_user_batch_\|rows\|affected //;s/(0\.00[0-9] sec/skipped/' | tr -d '()' | paste -d',' - - - | \
 column -ts, -o$'\t' -N Procedure,Rows,Time; tput sgr0;
*/



DROP SCHEMA IF EXISTS test_insert;
CREATE SCHEMA test_insert;
USE test_insert;

SET @max_users = 1000;
-- Slow procedures won't be executed if max users > skip_execution_if_max_records. Basically executes only v7
SET @skip_execution_if_max_records = 1000000;

DROP TABLE IF EXISTS user;

CREATE TABLE user
(
    id            INT AUTO_INCREMENT PRIMARY KEY,
    email         VARCHAR(320) NOT NULL,
    name          VARCHAR(32)  NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP    NULL     DEFAULT NULL
#     UNIQUE (email)
);

DELIMITER $$

DROP FUNCTION IF EXISTS rand_int $$
CREATE FUNCTION rand_int(start INT, end INT) RETURNS INT
    NO SQL
    RETURN start + FLOOR(RAND() * (end - start + 1)) $$

DROP FUNCTION IF EXISTS get_email $$
CREATE FUNCTION get_email(seed TEXT, len INT) RETURNS TEXT
    DETERMINISTIC
    RETURN CONCAT(LEFT(seed, len), '@', RIGHT(seed, len), '.com') $$

DROP FUNCTION IF EXISTS get_name $$
CREATE FUNCTION get_name(seed TEXT, len INT) RETURNS TEXT
    DETERMINISTIC
    RETURN LEFT(seed, len) $$

DROP FUNCTION IF EXISTS create_user_batch_v1_functions $$
CREATE FUNCTION create_user_batch_v1_functions(max INT) RETURNS TEXT
NO SQL
BEGIN
    DECLARE len TINYINT;
    DECLARE word, email, name VARCHAR(32);
    DECLARE v LONGTEXT DEFAULT '';

    REPEAT
        SET len = rand_int(6, 12);
        SET word = MD5(RAND());
        SET email = get_email(word, len);
        SET name = get_name(word, len);
        SET v = CONCAT(v, '("', email, '", "', name, '"),');

        SET max = max - 1;
    UNTIL max = 0 END REPEAT;
    SET v = TRIM(TRAILING ',' FROM v);

    RETURN CONCAT('insert ignore into user (email, name) values ', v);
END $$

# select create_user_batch_v1_functions(1000) $$

TRUNCATE user $$

DROP PROCEDURE IF EXISTS create_user_batch_v2_direct_insert $$
CREATE PROCEDURE create_user_batch_v2_direct_insert(max INT)
proc: BEGIN
    DECLARE len INT;
    DECLARE word, email, name TEXT;

    -- do not execute for more than X records, since this procedure is too slow
    IF max > @skip_execution_if_max_records THEN
        LEAVE proc;
    END IF;

    PREPARE stmt FROM 'INSERT IGNORE INTO user (email, name) VALUES (?, ?)';
    START TRANSACTION ;
    REPEAT
        SET len = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word = SHA1(RAND()),
            email = CONCAT(LEFT(word, len), '@', RIGHT(word, len), '.com'),
            name = LEFT(word, len);

        EXECUTE stmt USING email, name;

        SET max = max - 1;
        IF max % 1000 = 0 THEN
            COMMIT;
            START TRANSACTION;
        END IF;
    UNTIL max = 0 END REPEAT;
    COMMIT;
    DEALLOCATE PREPARE stmt;
END $$

CALL create_user_batch_v2_direct_insert(@max_users) $$

TRUNCATE user $$

# SET SESSION cte_max_recursion_depth = 1000000 $$ -- mysql, recursion depth
SET SESSION max_recursive_iterations = @max_users $$ -- mariadb

DROP PROCEDURE IF EXISTS create_user_batch_v3_recursion $$
CREATE PROCEDURE create_user_batch_v3_recursion(max INT)
proc: BEGIN

    -- do not execute for more than X records, since this procedure is too slow
    IF max > @skip_execution_if_max_records THEN
        LEAVE proc;
    END IF;

    INSERT IGNORE INTO user (email, name)
    WITH RECURSIVE cte AS
                       (SELECT 1                                                          AS i,
                               @len := 6 + FLOOR(RAND() * (12 - 6 + 1)),
                               @word := SHA1(RAND()),
                               CONCAT(LEFT(@word, @len), '@', RIGHT(@word, @len), '.com') AS email,
                               LEFT(@word, @len) AS name
                        UNION ALL
                        SELECT i + 1,
                               @len := 6 + FLOOR(RAND() * (12 - 6 + 1)),
                               @word := SHA1(RAND()),
                               CONCAT(LEFT(@word, @len), '@', RIGHT(@word, @len), '.com') AS email,
                               LEFT(@word, @len) AS name
                        FROM cte
                        WHERE i < max)
    SELECT email, name FROM cte;
END $$

CALL create_user_batch_v3_recursion(@max_users) $$

TRUNCATE user $$

CREATE PROCEDURE create_user_batch_v4_copy_paste(max INT)
proc: BEGIN
    DECLARE len1, len2, len3, len4, len5, len6, len7, len8, len9, len10 TINYINT;
    DECLARE word1, word2, word3, word4, word5, word6, word7, word8, word9, word10,
        email1, name1, email2, name2, email3, name3, email4, name4, email5, name5,
        email6, name6, email7, name7, email8, name8, email9, name9, email10, name10 VARCHAR(128);

    -- do not execute for more than X records, since this procedure is too slow
    IF max > @skip_execution_if_max_records THEN
        LEAVE proc;
    END IF;

    PREPARE insert_stmt FROM 'INSERT IGNORE INTO user (email, name) VALUES (?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?)';
    START TRANSACTION ;
    REPEAT
        SET len1 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word1 = SHA1(RAND()),
            email1 = CONCAT(LEFT(word1, len1), '@', RIGHT(word1, len1), '.com'),
            name1 = LEFT(word1, len1);
        SET len2 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word2 = SHA1(RAND()),
            email2 = CONCAT(LEFT(word2, len2), '@', RIGHT(word2, len2), '.com'),
            name2 = LEFT(word2, len2);
        SET len3 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word3 = SHA1(RAND()),
            email3 = CONCAT(LEFT(word3, len3), '@', RIGHT(word3, len3), '.com'),
            name3 = LEFT(word3, len3);
        SET len4 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word4 = SHA1(RAND()),
            email4 = CONCAT(LEFT(word4, len4), '@', RIGHT(word4, len4), '.com'),
            name4 = LEFT(word4, len4);
        SET len5 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word5 = SHA1(RAND()),
            email5 = CONCAT(LEFT(word5, len5), '@', RIGHT(word5, len5), '.com'),
            name5 = LEFT(word5, len5);
        SET len6 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word6 = SHA1(RAND()),
            email6 = CONCAT(LEFT(word6, len6), '@', RIGHT(word6, len6), '.com'),
            name6 = LEFT(word6, len6);
        SET len7 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word7 = SHA1(RAND()),
            email7 = CONCAT(LEFT(word7, len7), '@', RIGHT(word7, len7), '.com'),
            name7 = LEFT(word7, len7);
        SET len8 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word8 = SHA1(RAND()),
            email8 = CONCAT(LEFT(word8, len8), '@', RIGHT(word8, len8), '.com'),
            name8 = LEFT(word8, len8);
        SET len9 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word9 = SHA1(RAND()),
            email9 = CONCAT(LEFT(word9, len9), '@', RIGHT(word9, len9), '.com'),
            name9 = LEFT(word9, len9);
        SET len10 = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            word10 = SHA1(RAND()),
            email10 = CONCAT(LEFT(word10, len10), '@', RIGHT(word10, len10), '.com'),
            name10 = LEFT(word10, len10);

        EXECUTE insert_stmt USING email1, name1, email2, name2, email3, name3, email4, name4, email5, name5,
            email6, name6, email7, name7, email8, name8, email9, name9, email10, name10;
        SET max = max - 10;
        IF max % 1000 = 0 THEN
            COMMIT;
            START TRANSACTION;
        END IF;
    UNTIL max = 0 END REPEAT;
    COMMIT;
    DEALLOCATE PREPARE insert_stmt;
END $$

CALL create_user_batch_v4_copy_paste(@max_users) $$

TRUNCATE user $$

DROP PROCEDURE IF EXISTS create_user_batch_v5_improved_copy_paste $$
CREATE PROCEDURE create_user_batch_v5_improved_copy_paste(max INT)
proc: BEGIN
    DECLARE divider INT DEFAULT 10;
    DECLARE len INT UNSIGNED;
    DECLARE seed CHAR(40);
    DECLARE email1, name1, email2, name2, email3, name3, email4, name4, email5, name5,
        email6, name6, email7, name7, email8, name8, email9, name9, email10, name10 VARCHAR(64);

    -- do not execute for more than X records, since this procedure is too slow
    IF max > @skip_execution_if_max_records THEN
        LEAVE proc;
    END IF;

    PREPARE insert_stmt FROM 'INSERT IGNORE INTO user (email, name) VALUES (?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?)';
    START TRANSACTION ;
    REPEAT
        SET len = 6 + FLOOR(RAND() * (12 - 6 + 1)),
            seed = SHA1(RAND());

        SET email1 = CONCAT(SUBSTR(seed, 10, len), '@', SUBSTR(seed, 10, len), '.com'),
            name1 = SUBSTR(seed, 10, len),
            email2 = CONCAT(SUBSTR(seed, 1, len), '@', SUBSTR(seed, 1, len), '.net'),
            name2 = SUBSTR(seed, 1, len),
            email3 = CONCAT(SUBSTR(seed, 2, len), '@', SUBSTR(seed, 2, len), '.info'),
            name3 = SUBSTR(seed, 2, len),
            email4 = CONCAT(SUBSTR(seed, 3, len), '@', SUBSTR(seed, 3, len), '.ai'),
            name4 = SUBSTR(seed, 3, len),
            email5 = CONCAT(SUBSTR(seed, 4, len), '@', SUBSTR(seed, 4, len), '.app'),
            name5 = SUBSTR(seed, 4, len),
            email6 = CONCAT(SUBSTR(seed, 5, len), '@', SUBSTR(seed, 5, len), '.co'),
            name6 = SUBSTR(seed, 5, len),
            email7 = CONCAT(SUBSTR(seed, 6, len), '@', SUBSTR(seed, 6, len), '.gov'),
            name7 = SUBSTR(seed, 6, len),
            email8 = CONCAT(SUBSTR(seed, 9, len), '@', SUBSTR(seed, 9, len), '.biz'),
            name8 = SUBSTR(seed, 9, len),
            email9 = CONCAT(SUBSTR(seed, 7, len), '@', SUBSTR(seed, 7, len), '.me'),
            name9 = SUBSTR(seed, 7, len),
            email10 = CONCAT(SUBSTR(seed, 8, len), '@', SUBSTR(seed, 8, len), '.you'),
            name10 = SUBSTR(seed, 8, len);

        EXECUTE insert_stmt USING email1, name1, email2, name2, email3, name3, email4, name4, email5, name5,
            email6, name6, email7, name7, email8, name8, email9, name9, email10, name10;
        SET max = max - divider;
        IF max % 1000 = 0 THEN
            COMMIT;
            START TRANSACTION;
        END IF;
    UNTIL max = 0 END REPEAT;
    COMMIT;
    DEALLOCATE PREPARE insert_stmt;
END $$

CALL create_user_batch_v5_improved_copy_paste(@max_users) $$

TRUNCATE user $$

DROP PROCEDURE IF EXISTS create_user_batch_v6_dynamic_copy_paste $$
CREATE PROCEDURE create_user_batch_v6_dynamic_copy_paste(max INT)
proc: BEGIN
    DECLARE divider, i INT DEFAULT 10;
    DECLARE len INT DEFAULT 0;
    DECLARE word, vars TEXT DEFAULT '';

    -- do not execute for more than X records, since this procedure is too slow
    IF max > @skip_execution_if_max_records THEN
        LEAVE proc;
    END IF;

    -- since we're passing 10 records every time
    SET max = max DIV divider;

    PREPARE insert_stmt FROM 'INSERT IGNORE INTO user (email, name) VALUES (?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?),(?, ?)';
    REPEAT
        SET i = divider;
        REPEAT
            SET len = 6 + FLOOR(RAND() * (12 - 6 + 1)),
                word = SHA1(RAND());
            SET vars = CONCAT(
                    'SET ', '@email', i, ' = "', CONCAT(LEFT(word, len), '@', RIGHT(word, len), '.com'), '", ',
                    '@name', i, ' = "', LEFT(word, len), '";'
                );

            PREPARE var_stmt FROM vars;
            EXECUTE var_stmt;
            DEALLOCATE PREPARE var_stmt;

            EXECUTE insert_stmt USING @email1, @name1, @email2, @name2, @email3, @name3, @email4, @name4, @email5, @name5,
                @email6, @name6, @email7, @name7, @email8, @name8, @email9, @name9, @email10, @name10;

            SET i = i - 1;
        UNTIL i = 0 END REPEAT;

        SET max = max - divider;

    UNTIL max = 0 END REPEAT;
    DEALLOCATE PREPARE insert_stmt;
END $$

CALL create_user_batch_v6_dynamic_copy_paste(@max_users) $$

TRUNCATE user $$

/*

The create_user_batch_v7_joins code is not dynamic and ignores @max_users

*/
DROP PROCEDURE IF EXISTS create_user_batch_v7_joins $$
CREATE PROCEDURE create_user_batch_v7_joins()
proc: BEGIN
    START TRANSACTION ;
    INSERT IGNORE INTO user (email, name)
    SELECT CONCAT(SUBSTR(seed, len - 5, len), '@', SUBSTR(seed, len - 5, len), '.com') email,
           LEFT(seed, 8)                                                               name
    FROM
            (
                select sha1(a.N + b.N * 10 + c.N * 100 + d.N * 1000 + e.N * 10000 + 1) seed, 6 + FLOOR(RAND() * (12 - 6 + 1)) len -- 100K
#                 select sha1(a.N + b.N * 10 + c.N * 100 + d.N * 1000 + e.N * 10000 + f.N * 100000 + 1) seed, 6 + FLOOR(RAND() * (12 - 6 + 1)) len -- 1M
#                 select sha1(a.N + b.N * 10 + c.N * 100 + d.N * 1000 + e.N * 10000 + f.N * 100000 + g.N * 1000000 + 1) seed, 6 + FLOOR(RAND() * (12 - 6 + 1)) len -- 10M
#                 select sha1(a.N + b.N * 10 + c.N * 100 + d.N * 1000 + e.N * 10000 + f.N * 100000 + g.N * 1000000 + h.N * 10000000 + 1) seed, 6 + FLOOR(RAND() * (12 - 6 + 1)) len -- 100M
                from (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) a
                   , (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) b
                   , (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) c
                   , (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) d
                   , (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) e -- 100K
#                    , (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) f -- 1M
#                    , (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) g -- 10M
#                    , (select 0 as N union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9) h -- 100M
            ) t;
    COMMIT ;
END $$

CALL create_user_batch_v7_joins() $$

DELIMITER ;
