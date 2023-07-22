SELECT 
    *
FROM
    netflix.netflix2;
use netflix;
SELECT 
    COUNT(*)
FROM
    netflix2;
Segment 1: Database - Tables, Columns, Relationships
1.Identify the tables in the dataset and their respective columns.
SELECT table_name,
       COLUMN_NAME,
       DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'netflix';

2.Determine the number of rows in each table within the schema.
select table_name,
       table_rows
from  INFORMATION_SCHEMA.TABLES
where table_schema = 'netflix'; -- approximate row count
select count(*) from netflix2 -- 8790
-- Dynamic sql to get row count of each table in schema
SET @schema_name = 'netflix';
SET @sql = NULL;
SELECT 
    GROUP_CONCAT(CONCAT('SELECT \'',
                table_name,
                '\' AS table_name, COUNT(*) AS row_count FROM ',
                table_name)
        SEPARATOR ' UNION ALL ')
INTO @sql FROM
    information_schema.tables
WHERE
    table_schema = @schema_name;
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
 
3.Identify and handle any missing values in the dataset.
select *
from netflix2
where type  = 'Not Given'
   or title = 'Not Given'
   or duration = 'Not Given'
   or listed_in = 'Not Given';
SELECT 
    COALESCE(show_id, 'default_value') AS show_id,
    COALESCE(type, 'default_value') AS type,
    COALESCE(title, 'default_value') AS title
    COALESCE(director, 'default_value') AS director,
    COALESCE(country, 'default_value') AS country,
    COALESCE(date_added, 'default_value') AS date_added,
    COALESCE(release_year, 'default_value') AS release_year,
    COALESCE(rating, 'default_value') AS rating,
    COALESCE(duration, 'default_value') AS duration,
    COALESCE(listed_in, 'default_value') AS listed_in,
    netflix2; 

Segment 2: Content Analysis
1.Analyse the distribution of content types (movies vs. TV shows) in the dataset.
SELECT type, COUNT(*) as count
FROM netflix2
GROUP BY type;
2.Determine the top 10 countries with the highest number of productions on Netflix.
select country,count(show_id) as cnt from netflix2
group by country
order by cnt desc
limit 10;
3.Investigate the trend of content additions over the years.
SELECT listed_in, release_year, count(*)
FROM netflix2
group by listed_in,release_year
ORDER BY listed_in,release_year;
4.Analyse the relationship between content duration and release year.
select release_year,avg(duration)
from netflix2
group by release_year
order by release_year;
5.Identify the directors with the most content on Netflix.
select director,count(distinct listed_in) as cnt from netflix2
group by director
order by cnt desc;

SELECT 
    director, COUNT(DISTINCT show_id) AS cnt
FROM
    netflix2
GROUP BY director
ORDER BY cnt DESC;

Segment 3: Genre and Category Analysis
1. Determine the unique genres and categories present in the dataset.
 select distinct listed_in , type from netflix2;
 2.Calculate the percentage of movies and TV shows in each genre.
WITH total_movie_count AS (
    SELECT COUNT(*) AS total
    FROM netflix2
),
genre_movie_count AS (
    SELECT listed_in, type, COUNT(*) AS tot_movies_count
    FROM netflix2
    GROUP BY listed_in,type
),
genre_view as (
select listed_in,type,tot_movies_count,total
from genre_movie_count cross join total_movie_count)
select listed_in,type, tot_movies_count*100/total as percentage from genre_view;
3.Identify the most popular genres/categories based on the number of productions.
select listed_in,count(show_id) as cnt from
netflix2
group by listed_in 
order by cnt desc
limit 1;
4.Calculate the cumulative sum of content duration within each genre.
SELECT listed_in,show_id, duration, SUM(duration) OVER (PARTITION BY listed_in ORDER BY listed_in,show_id,duration ) AS cumulative_sum
FROM netflix2;
Segment 4: Release Date Analysis
1.Determine the distribution of content releases by month and year.
SELECT 
    listed_in,
    release_year,
  Month(STR_TO_DATE(date_added, '%m/%d/%Y')) AS release_month,
  count(*) as cnt
FROM netflix2
GROUP BY listed_in, release_year, Month(STR_TO_DATE(date_added, '%m/%d/%Y'))
ORDER BY listed_in,release_year,release_month;
The winter months are in December, January and February.
The spring months in March, April and May.
The summer months in June, July and August.
And the autumn months in September, October and November.
2.Analyse the seasonal patterns in content releases.
SELECT 
   COUNT(*) AS release_count,
   case when coalesce(Month(STR_TO_DATE(date_added, '%m/%d/%Y')),13) in (12,1,2) then 'WINTER'
        when coalesce(Month(STR_TO_DATE(date_added, '%m/%d/%Y')),13) in (3,4,5) then 'SPRING'
        when coalesce(Month(STR_TO_DATE(date_added, '%m/%d/%Y')),13) in (6,7,8) then 'SUMMER'
        when coalesce(Month(STR_TO_DATE(date_added, '%m/%d/%Y')),13) in (9,10,11) then 'AUTUMN'
        else 'SEASON_UNKNOWN'
        end as 'SEASON'
FROM netflix2
GROUP BY SEASON
ORDER BY count(*) desc;
3.Identify the months and years with the highest number of releases.
SELECT 
    MONTH(STR_TO_DATE(date_added, '%m/%d/%Y')) AS release_month,
     release_year,
    COUNT(*) AS release_count
FROM netflix2
GROUP BY release_month, release_year
ORDER BY release_count  DESC
limit 1;
_- -Netflix is focused on modern content;
--Both TV shows and Movies are increasing with the same tendency on platform.
Segment 5: Rating Analysis
1.Investigate the distribution of ratings across different genres.
SELECT 
    listed_in,
    rating,
    COUNT(*) AS count
FROM netflix2
GROUP BY listed_in, rating
ORDER BY listed_in, rating,count desc;
Rating Description:

--TV-MA (Mature Audiences Only): Intended for mature audiences and not suitable for children under 17. The content may include intense violence, strong language, sexual content, or other adult themes.
--TV-14 (Parents Strongly Cautioned): Some material may not be suitable for children under 14. Parents are urged to exercise caution as the content may contain intense violence, sexual content, crude humor, or strong language.
--TV-PG (Parental Guidance Suggested): Some material may not be suitable for young children. Parents are encouraged to provide "parental guidance" as the content may contain mild violence, suggestive dialogue, or some coarse language.
--R (Restricted): Restricted to viewers over 17 years old or those accompanied by a parent or adult guardian. The content may include strong language, intense violence, nudity, drug use, or other adult themes. This rating is typically used for movies rather than TV shows.
--PG-13 (Parents Strongly Cautioned): Some material may be inappropriate for children under 13 years old. Parents are urged to be cautious as the content may contain violence, brief nudity, or mild language. This rating is typically used for movies rather than TV shows.

TV-Y7 (Directed to Older Children): Intended for children age 7 and above. The content is designed to be suitable for older children and may include some mild fantasy violence or comedic elements.

TV-Y (All Children): Suitable for all children. The content is designed to be appropriate for children of all ages and does not include any material that could be considered objectionable.

_-- PG (Parental Guidance Suggested): Some material may not be suitable for young children. Parents are urged to provide "parental guidance" as the content may include some material that young viewers may find confusing or upsetting.
-- NR (Not Rated): The content has not been assigned a specific rating. This can occur for various reasons, such as independent films or content not submitted for rating.
-- G (General Audience): Suitable for all ages. The content is considered appropriate for everyone, including young children. This rating is typically used for movies rather than TV shows.
-- TV-Y7-FV (Directed to Older Children - Fantasy Violence): Intended for children age 7 and above. The content may contain more intense or frequent fantasy violence compared to TV-Y7-rated shows.
-- UR (Unrated): The content has not been assigned a specific rating or is an unrated version of a rated film. Viewers should exercise caution and consider the content's nature before watching.
Key:

-- The Target Audience of Netflix is mature people. Leading content rating is intended for them (TV-MA,R);
 -- Second big auditory is teenagers (TV-14, TV-PG). A lot of content allowed them to watch wide adversity of content, but probably parents supervision is recommended or required.
2.Analyse the relationship between ratings and content duration.
WITH duration_cte AS (
    SELECT rating, duration
    FROM netflix2
    WHERE type = 'Movie'
    UNION ALL
    SELECT rating, CAST(SUBSTR(duration, 1, INSTR(duration, ' ') - 1) AS SIGNED) * 30 AS duration
    FROM netflix2
    WHERE type = 'TV Show'
)
SELECT rating, AVG(duration) as avg_duration
FROM duration_cte
GROUP BY rating
ORDER BY avg_duration DESC;
---For TV shows, it extracts the number of episodes from the duration column and multiplies it by 30 to get the total duration in minutes
Segment 6: Co-occurrence Analysis
1.Identify the most common pairs of genres/categories that occur together in content.
WITH genre_pairs AS (
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n.n), ',', -1)) AS genre1,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n.n + 1), ',', -1)) AS genre2
    FROM netflix2
    CROSS JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) AS n
    WHERE n.n <= CHAR_LENGTH(listed_in) - CHAR_LENGTH(REPLACE(listed_in, ',', '')) + 1
)
SELECT 
    genre1,
    genre2,
    COUNT(*) AS count
FROM genre_pairs
WHERE genre1 <> '' AND genre2 <> ''
GROUP BY genre1, genre2
ORDER BY count DESC;

2.Analyse the relationship between genres/categories and content duration.
WITH genres AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        duration
    FROM netflix2
    UNION ALL
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', 2), ',', -1)) AS genre,
        duration
    FROM netflix2
    WHERE listed_in LIKE '%,%'
    UNION ALL
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', 3), ',', -1)) AS genre,
        duration
    FROM netflix2
    WHERE listed_in LIKE '%,%,%'
)
SELECT 
    genre,
    AVG(duration) AS avg_duration
FROM genres
GROUP BY genre
ORDER BY avg_duration DESC;

Segment 7: International Expansion Analysis
1.Identify the countries where Netflix has expanded its content offerings.
select country, count(*) as count
from netflix2
where country != 'Not Given'
group by country
order by count desc;

....Most of content made in USA. Far behind, but also in the top are India, UK, Pakistan. Leadership is closed by Canada, Japan, France and South Korea.

    2.Analyse the distribution of content types in different countries.
  SELECT country, COUNT(*) as cnt
FROM netflix2
WHERE type = 'Movie'
GROUP BY country
ORDER BY cnt DESC;

SELECT 
    country, COUNT(*) AS cnt
FROM
    netflix2
WHERE
    type = 'TV Show'
GROUP BY country
ORDER BY cnt DESC;
   3.Investigate the relationship between content duration and country of production.
  WITH duration_cte AS (
    SELECT country, duration
    FROM netflix2
    WHERE type = 'Movie'
    UNION ALL
    SELECT country, CAST(SUBSTR(duration, 1, INSTR(duration, ' ') - 1) AS SIGNED) * 30 AS duration
    FROM netflix2
    WHERE type = 'TV Show'
)
SELECT country, AVG(duration) as avg_duration
FROM duration_cte
GROUP BY country
ORDER BY avg_duration DESC;

    Segment 8: Recommendations for Content Strategy
    

1.Based on the analysis, provide recommendations for the types of content Netflix should focus on producing
a.Netflix is focused on modern content;

b.Both TV shows and Movies are increasing with the same tendency on platform.
 Conclusion:

-- Modern content, which includes recent releases and trending topics, often generates more interest and engagement among viewers.
-- To differentiate themselves and attract a larger audience, Netflix invests heavily in acquiring and producing new, exclusive content. By focusing on modern content, they aim to offer fresh and up-to-date content that stands out in the market.
-- Netflix has established partnerships with acclaimed directors, producers, and content creators in many countries, allowing them to produce original content that aligns with current trends and storytelling techniques. That helps to produce diverse content for every taste, increasing it's amount.
-- Advances in technology have made it easier and more cost-effective to produce and distribute content. This has led to an increase in the number of TV shows and movies being produced globally.

2.Identify potential areas for expansion and growth based on the analysis of the dataset.
a.Nearly half of content consist Drama or Comedy genres;
b.2/3 of content on Netflix are movies.
Movies typically have a finite duration and tell a complete story within that timeframe. This format allows for a concentrated and immersive viewing experience, often attracting a broad range of audiences. Series, on the other hand, involve multiple episodes or seasons, requiring a longer time commitment from viewers. This tendency works not only for Netflix, but for the whole indusrtry in general.
Most of content made in USA. Far behind, but also in the top are India, UK, Pakistan. Leadership is closed by Canada, Japan, France and South Korea.
The United States has the largest entertainment market globally, both in terms of domestic audience size and international reach. Its robust film and television industry, supported by substantial investments and infrastructure, allows for the production of a wide range of content. Similarly, countries like India, with its massive population and thriving film industry (commonly referred to as Bollywood), have a significant domestic market and are known for producing a large volume of content. Economic factors play a crucial role in driving production and attracting investments.
USA has a long history of filmmaking and television production, dating back to the early 20th century. This legacy, coupled with advancements in technology, has allowed the country to establish itself as a leader in the industry. Similarly, countries like the UK and France have a rich cinematic heritage and have made significant contributions to the world of film and television.
English is widely spoken and understood globally, giving media content produced in English-speaking countries, particularly the United States and the United Kingdom, an advantage in terms of international distribution. Additionally, the cultural influence of these countries, through their music, fashion, and entertainment industries, has contributed to the popularity of their content on a global scale.
Conclusions
Key:

2/3 of content on Netflix are movies.
Conclusion: Movies typically have a finite duration and tell a complete story within that timeframe. This format allows for a concentrated and immersive viewing experience, often attracting a broad range of audiences. Series, on the other hand, involve multiple episodes or seasons, requiring a longer time commitment from viewers. This tendency works not only for Netflix, but for the whole indusrtry in general.

Key:

Most of content made in USA. Far behind, but also in the top are India, UK, Pakistan. Leadership is closed by Canada, Japan, France and South Korea.
Conclusion:

The United States has the largest entertainment market globally, both in terms of domestic audience size and international reach. Its robust film and television industry, supported by substantial investments and infrastructure, allows for the production of a wide range of content. Similarly, countries like India, with its massive population and thriving film industry (commonly referred to as Bollywood), have a significant domestic market and are known for producing a large volume of content. Economic factors play a crucial role in driving production and attracting investments.
USA has a long history of filmmaking and television production, dating back to the early 20th century. This legacy, coupled with advancements in technology, has allowed the country to establish itself as a leader in the industry. Similarly, countries like the UK and France have a rich cinematic heritage and have made significant contributions to the world of film and television.

English is widely spoken and understood globally, giving media content produced in English-speaking countries, particularly the United States and the United Kingdom, an advantage in terms of international distribution. Additionally, the cultural influence of these countries, through their music, fashion, and entertainment industries, has contributed to the popularity of their content on a global scale.

Some countries actively support their local film and television industries through government funding, tax incentives, and supportive policies. This support helps create a favorable environment for production and encourages local talent and creativity. For example, countries like Canada, South Korea, and France have implemented various measures to promote their local industries and attract international productions.

Many countries, including Canada, Japan, and South Korea, have a vibrant entertainment industry that produces content catering to their domestic audiences and has gained recognition and popularity worldwide.

Key:

Netflix is focused on modern content;
Both TV shows and Movies are increasing with the same tendency on platform.
