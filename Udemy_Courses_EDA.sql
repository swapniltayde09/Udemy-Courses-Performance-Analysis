
Create Database udemy_courses;

Use udemy_courses;

-- 1. Convert dates first (one-time setup)
ALTER TABLE udemy_courses 
ADD COLUMN created_date DATE,
ADD COLUMN published_date DATE;

UPDATE udemy_courses
SET created_date = STR_TO_DATE(created, '%d-%m-%Y'),
    published_date = STR_TO_DATE(published_time, '%d-%m-%Y');

-- Essential Indexes
CREATE INDEX idx_subs_rating ON udemy_courses(num_subscribers DESC, avg_rating DESC);
CREATE INDEX idx_reviews ON udemy_courses(num_reviews DESC);
CREATE INDEX idx_price ON udemy_courses(discounted_price_amount);
CREATE INDEX idx_date ON udemy_courses(published_date);

-- Verify Index usage
EXPLAIN 
SELECT * 
FROM udemy_courses 
ORDER BY num_subscribers DESC 
LIMIT 10;

-- ===================================
-- Phase 2: Data Understanding
-- ===================================
-- 2. Dataset overview
SELECT 
    COUNT(*) AS total_courses,
    COUNT(DISTINCT id) AS unique_courses,
    SUM(is_paid) AS paid_courses,
    ROUND(AVG(avg_rating), 2) AS avg_rating,
    ROUND(AVG(num_subscribers), 0) AS avg_subscribers,
    ROUND(AVG(num_reviews), 0) AS avg_reviews,
    ROUND(AVG(num_published_lectures), 0) AS avg_lectures
FROM udemy_courses;

-- 3. Column data types and nulls
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'udemy_courses';

-- 4. Feature Extraction : Categorizing our Courses
SELECT 
    title,
    CASE 
        WHEN LOWER(title) LIKE '%sql%' OR LOWER(title) LIKE '%mysql%' OR LOWER(title) LIKE '%database%' OR LOWER(title) LIKE '%postgres%' THEN 'Database'
        WHEN LOWER(title) LIKE '%tableau%' OR LOWER(title) LIKE '%power bi%' OR LOWER(title) LIKE '%visualization%' OR LOWER(title) LIKE '%dashboard%' THEN 'Data Visualization'
        WHEN LOWER(title) LIKE '%excel%' OR LOWER(title) LIKE '%spreadsheet%' OR LOWER(title) LIKE '%google sheets%' THEN 'Spreadsheet'
        WHEN LOWER(title) LIKE '%agile%' OR LOWER(title) LIKE '%scrum%' OR LOWER(title) LIKE '%pmp%' OR LOWER(title) LIKE '%project management%' THEN 'Project Management'
        WHEN LOWER(title) LIKE '%finance%' OR LOWER(title) LIKE '%financial%' OR LOWER(title) LIKE '%accounting%' OR LOWER(title) LIKE '%bookkeep%' OR LOWER(title) LIKE '%audit%' OR LOWER(title) LIKE '%tax%' OR LOWER(title) LIKE '%cpa%' OR LOWER(title) LIKE '%cfa%' THEN 'Finance'
        WHEN LOWER(title) LIKE '%mba%' OR LOWER(title) LIKE '%business%' OR LOWER(title) LIKE '%enterprise%' THEN 'Business'
        WHEN LOWER(title) LIKE '%writing%' OR LOWER(title) LIKE '%screenwriting%' OR LOWER(title) LIKE '%copywriting%' OR LOWER(title) LIKE '%content%' THEN 'Writing'
        WHEN LOWER(title) LIKE '%sales%' OR LOWER(title) LIKE '%marketing%' OR LOWER(title) LIKE '%ppc%' OR LOWER(title) LIKE '%funnel%' THEN 'Sales/Marketing'
        WHEN LOWER(title) LIKE '%data science%' OR LOWER(title) LIKE '%analytics%' OR LOWER(title) LIKE '%machine learning%' OR LOWER(title) LIKE '%ml%' OR LOWER(title) LIKE '%ai%' THEN 'Data Science'
        WHEN LOWER(title) LIKE '%manage%' OR LOWER(title) LIKE '%management%' THEN 'Management'
        WHEN LOWER(title) LIKE '%leadership%' OR LOWER(title) LIKE '%leader%' THEN 'Leadership'
        WHEN LOWER(title) LIKE '%communication%' OR LOWER(title) LIKE '%public speaking%' OR LOWER(title) LIKE '%presentation%' THEN 'Communication'
        ELSE 'Other'
    END AS category
FROM udemy_courses;

-- Count by category
SELECT 
    category,
    COUNT(*) AS num_courses
FROM (
    -- Above CASE statement as subquery
    SELECT 
		title,
		CASE 
			WHEN LOWER(title) LIKE '%sql%' OR LOWER(title) LIKE '%mysql%' OR LOWER(title) LIKE '%database%' OR LOWER(title) LIKE '%postgres%' THEN 'Database'
			WHEN LOWER(title) LIKE '%tableau%' OR LOWER(title) LIKE '%power bi%' OR LOWER(title) LIKE '%visualization%' OR LOWER(title) LIKE '%dashboard%' THEN 'Data Visualization'
			WHEN LOWER(title) LIKE '%excel%' OR LOWER(title) LIKE '%spreadsheet%' OR LOWER(title) LIKE '%google sheets%' THEN 'Spreadsheet'
			WHEN LOWER(title) LIKE '%agile%' OR LOWER(title) LIKE '%scrum%' OR LOWER(title) LIKE '%pmp%' OR LOWER(title) LIKE '%project management%' THEN 'Project Management'
			WHEN LOWER(title) LIKE '%finance%' OR LOWER(title) LIKE '%financial%' OR LOWER(title) LIKE '%accounting%' OR LOWER(title) LIKE '%bookkeep%' OR LOWER(title) LIKE '%audit%' OR LOWER(title) LIKE '%tax%' OR LOWER(title) LIKE '%cpa%' OR LOWER(title) LIKE '%cfa%' THEN 'Finance'
			WHEN LOWER(title) LIKE '%mba%' OR LOWER(title) LIKE '%business%' OR LOWER(title) LIKE '%enterprise%' THEN 'Business'
			WHEN LOWER(title) LIKE '%writing%' OR LOWER(title) LIKE '%screenwriting%' OR LOWER(title) LIKE '%copywriting%' OR LOWER(title) LIKE '%content%' THEN 'Writing'
			WHEN LOWER(title) LIKE '%sales%' OR LOWER(title) LIKE '%marketing%' OR LOWER(title) LIKE '%ppc%' OR LOWER(title) LIKE '%funnel%' THEN 'Sales/Marketing'
			WHEN LOWER(title) LIKE '%data science%' OR LOWER(title) LIKE '%analytics%' OR LOWER(title) LIKE '%machine learning%' OR LOWER(title) LIKE '%ml%' OR LOWER(title) LIKE '%ai%' THEN 'Data Science'
			WHEN LOWER(title) LIKE '%manage%' OR LOWER(title) LIKE '%management%' THEN 'Management'
			WHEN LOWER(title) LIKE '%leadership%' OR LOWER(title) LIKE '%leader%' THEN 'Leadership'
			WHEN LOWER(title) LIKE '%communication%' OR LOWER(title) LIKE '%public speaking%' OR LOWER(title) LIKE '%presentation%' THEN 'Communication'
			ELSE 'Other'
		END AS category
    FROM udemy_courses
) t
GROUP BY category
ORDER BY num_courses DESC;

-- ===============================================
-- Phase 4: Univariate Analysis
-- ==============================================
-- 5. Subscribers distribution (top 10, quartiles) 	
WITH ranked_data AS (
    SELECT 
        num_subscribers,
        NTILE(4) OVER (ORDER BY num_subscribers) AS quartile
    FROM udemy_courses
)
SELECT
    MAX(CASE WHEN quartile = 1 THEN num_subscribers END) AS q25_subscribers,
    MAX(CASE WHEN quartile = 2 THEN num_subscribers END) AS median_subscribers,
    MAX(CASE WHEN quartile = 3 THEN num_subscribers END) AS q75_subscribers
FROM ranked_data;

-- 6. Rating distribution
SELECT 
    ROUND(avg_rating, 1) AS rating_bucket,
    COUNT(*) AS course_count,
    AVG(num_subscribers) AS avg_subs_per_rating,
    AVG(num_reviews) AS avg_reviews_per_rating
FROM udemy_courses 
GROUP BY ROUND(avg_rating, 1)
ORDER BY rating_bucket;

-- 7. Price analysis (free vs paid)
SELECT 
    is_paid,
    COUNT(*) AS course_count,
    AVG(discounted_price_amount) AS avg_discounted_price,
    AVG(price_detail_amount) AS avg_original_price,
    AVG(num_subscribers) AS avg_subscribers
FROM
    udemy_courses
GROUP BY is_paid;

-- Growth Analysis
-- 1. Courses per year
SELECT 
    YEAR(STR_TO_DATE(published_time, '%d-%m-%Y')) AS year,
    COUNT(*) AS num_courses_published,
    ROUND(AVG(num_reviews), 0) AS avg_reviews
FROM udemy_courses 
GROUP BY YEAR(STR_TO_DATE(published_time, '%d-%m-%Y'))
ORDER BY year;

-- 2. Year-over-year growth %
WITH yearly_stats AS (
    SELECT 
        YEAR(STR_TO_DATE(published_time, '%d-%m-%Y')) AS year,
        COUNT(*) AS num_courses
    FROM udemy_courses 
    GROUP BY 1
)
SELECT 
    year,
    num_courses,
    LAG(num_courses) OVER (ORDER BY year) AS prev_year,
    ROUND(((num_courses - LAG(num_courses) OVER (ORDER BY year)) / LAG(num_courses) OVER (ORDER BY year)) * 100, 0) AS growth_pct
FROM yearly_stats 
ORDER BY year;

-- Number of Courses and Average Number of Reviews by Category
SELECT 
    CASE 
        WHEN LOWER(title) LIKE '%finance%' OR LOWER(title) LIKE '%accounting%' 
          OR LOWER(title) LIKE '%bookkeep%' OR LOWER(title) LIKE '%audit%' 
          OR LOWER(title) LIKE '%tax%' OR LOWER(title) LIKE '%cpa%' 
          OR LOWER(title) LIKE '%cma%' OR LOWER(title) LIKE '%cfa%' 
        THEN 'Finance/Accounting'
        WHEN LOWER(title) LIKE '%business%' OR LOWER(title) LIKE '%entrepreneur%' 
          OR LOWER(title) LIKE '%startup%' OR LOWER(title) LIKE '%management%' 
          OR LOWER(title) LIKE '%marketing%' OR LOWER(title) LIKE '%sales%' 
          OR LOWER(title) LIKE '%leadership%'
        THEN 'Business/Management'
        ELSE 'Other'
    END AS category,
    COUNT(*) AS num_courses,
    ROUND(AVG(num_reviews), 2) AS avg_reviews
FROM udemy_courses 
GROUP BY 1
ORDER BY num_courses DESC;

-- ================================================
-- Phase 5: Bivariate/Relationships
-- ================================================
-- 8. Correlations (Lectures ↔ Subscribers, Rating ↔ Subscribers)
SELECT 
    -- Lectures vs Subscribers
    (COUNT(*) * SUM(num_published_lectures * num_subscribers) 
     - SUM(num_published_lectures) * SUM(num_subscribers)
    ) / SQRT(
        (COUNT(*) * SUM(num_published_lectures * num_published_lectures) 
         - POW(SUM(num_published_lectures), 2)
        ) * (COUNT(*) * SUM(num_subscribers * num_subscribers) 
             - POW(SUM(num_subscribers), 2)
        )
    ) AS corr_lectures_subscribers,

    -- Rating vs Subscribers  
    (COUNT(*) * SUM(avg_rating * num_subscribers) 
     - SUM(avg_rating) * SUM(num_subscribers)
    ) / SQRT(
        (COUNT(*) * SUM(avg_rating * avg_rating) 
         - POW(SUM(avg_rating), 2)
        ) * (COUNT(*) * SUM(num_subscribers * num_subscribers) 
             - POW(SUM(num_subscribers), 2)
        )
    ) AS corr_rating_subscribers,

    -- Reviews vs Subscribers
    (COUNT(*) * SUM(num_reviews * num_subscribers) 
     - SUM(num_reviews) * SUM(num_subscribers)
    ) / SQRT(
        (COUNT(*) * SUM(num_reviews * num_reviews) 
         - POW(SUM(num_reviews), 2)
        ) * (COUNT(*) * SUM(num_subscribers * num_subscribers) 
             - POW(SUM(num_subscribers), 2)
        )
    ) AS corr_reviews_subscribers

FROM udemy_courses;

-- CREATE INDEX idx_title ON udemy_courses(title(255));
CREATE INDEX idx_subscribers ON udemy_courses(num_subscribers);

-- 9. Paid vs Free performance comparison
SELECT 
    is_paid,
    AVG(avg_rating) AS avg_rating,
    AVG(num_subscribers) AS avg_subs,
    AVG(num_reviews) AS avg_reviews,
    AVG(discounted_price_amount) AS avg_price
FROM udemy_courses 
GROUP BY is_paid;

-- =========================================
-- Phase 6: Top Performers/Rankings
-- =========================================
-- 10. Top 10 
-- Top 10 Courses by Number of Subscribers
SELECT 
    title,
    num_subscribers,
    ROUND(avg_rating, 2) AS avg_rating,
    discounted_price_amount,
    num_reviews,
    num_published_lectures
FROM udemy_courses 
ORDER BY num_subscribers DESC 
LIMIT 10;

-- Top 10 most expensive (original price), descending
SELECT 
    title,
    price_detail_amount AS original_price,
    discounted_price_amount AS current_price,
    ROUND(avg_rating, 2) AS avg_rating,
    num_subscribers,
    num_reviews
FROM udemy_courses 
WHERE price_detail_amount IS NOT NULL
ORDER BY price_detail_amount DESC, num_subscribers DESC
LIMIT 10;

-- Top 10 Courses by Rating
SELECT 
    title,
    ROUND(avg_rating, 2) AS avg_rating,
    num_subscribers,
    discounted_price_amount,
    num_reviews,
    num_published_lectures
FROM udemy_courses 
ORDER BY avg_rating DESC, num_reviews DESC, num_subscribers DESC
LIMIT 10;

-- Category Performance: Subscribers, Rating, Reviews by Category
SELECT 
    category,
    COUNT(*) AS num_courses,
    ROUND(AVG(avg_rating), 2) AS avg_rating,
    ROUND(AVG(num_subscribers), 0) AS avg_subscribers,
    ROUND(AVG(num_reviews), 0) AS avg_reviews,
    ROUND(AVG(num_published_lectures), 0) AS avg_lectures
FROM (
    SELECT 
		title, 
        avg_rating, 
        num_subscribers, 
        num_reviews, 
        num_published_lectures,
		CASE
			WHEN LOWER(title) LIKE '%sql%' OR LOWER(title) LIKE '%mysql%' OR LOWER(title) LIKE '%database%' OR LOWER(title) LIKE '%postgres%' THEN 'Database'
			WHEN LOWER(title) LIKE '%tableau%' OR LOWER(title) LIKE '%power bi%' OR LOWER(title) LIKE '%visualization%' OR LOWER(title) LIKE '%dashboard%' THEN 'Data Visualization'
			WHEN LOWER(title) LIKE '%excel%' OR LOWER(title) LIKE '%spreadsheet%' OR LOWER(title) LIKE '%google sheets%' THEN 'Spreadsheet'
			WHEN LOWER(title) LIKE '%agile%' OR LOWER(title) LIKE '%scrum%' OR LOWER(title) LIKE '%pmp%' OR LOWER(title) LIKE '%project management%' THEN 'Project Management'
			WHEN LOWER(title) LIKE '%finance%' OR LOWER(title) LIKE '%financial%' OR LOWER(title) LIKE '%accounting%' OR LOWER(title) LIKE '%bookkeep%' OR LOWER(title) LIKE '%audit%' OR LOWER(title) LIKE '%tax%' OR LOWER(title) LIKE '%cpa%' OR LOWER(title) LIKE '%cfa%' THEN 'Finance'
			WHEN LOWER(title) LIKE '%mba%' OR LOWER(title) LIKE '%business%' OR LOWER(title) LIKE '%enterprise%' THEN 'Business'
			WHEN LOWER(title) LIKE '%writing%' OR LOWER(title) LIKE '%screenwriting%' OR LOWER(title) LIKE '%copywriting%' OR LOWER(title) LIKE '%content%' THEN 'Writing'
			WHEN LOWER(title) LIKE '%sales%' OR LOWER(title) LIKE '%marketing%' OR LOWER(title) LIKE '%ppc%' OR LOWER(title) LIKE '%funnel%' THEN 'Sales/Marketing'
			WHEN LOWER(title) LIKE '%data science%' OR LOWER(title) LIKE '%analytics%' OR LOWER(title) LIKE '%machine learning%' OR LOWER(title) LIKE '%ml%' OR LOWER(title) LIKE '%ai%' THEN 'Data Science'
			WHEN LOWER(title) LIKE '%manage%' OR LOWER(title) LIKE '%management%' THEN 'Management'
			WHEN LOWER(title) LIKE '%leadership%' OR LOWER(title) LIKE '%leader%' THEN 'Leadership'
			WHEN LOWER(title) LIKE '%communication%' OR LOWER(title) LIKE '%public speaking%' OR LOWER(title) LIKE '%presentation%' THEN 'Communication'
			ELSE 'Other'
		END AS category
	FROM udemy_courses
) t
GROUP BY category
ORDER BY avg_subscribers DESC;

-- Top Category by Subscribers
SELECT 
    category,
    SUM(num_subscribers) AS total_subscribers,
    COUNT(*) AS num_courses
FROM (
    SELECT 
		title, 
        num_subscribers, 
		CASE
			WHEN LOWER(title) LIKE '%sql%' OR LOWER(title) LIKE '%mysql%' OR LOWER(title) LIKE '%database%' OR LOWER(title) LIKE '%postgres%' THEN 'Database'
			WHEN LOWER(title) LIKE '%tableau%' OR LOWER(title) LIKE '%power bi%' OR LOWER(title) LIKE '%visualization%' OR LOWER(title) LIKE '%dashboard%' THEN 'Data Visualization'
			WHEN LOWER(title) LIKE '%excel%' OR LOWER(title) LIKE '%spreadsheet%' OR LOWER(title) LIKE '%google sheets%' THEN 'Spreadsheet'
			WHEN LOWER(title) LIKE '%agile%' OR LOWER(title) LIKE '%scrum%' OR LOWER(title) LIKE '%pmp%' OR LOWER(title) LIKE '%project management%' THEN 'Project Management'
			WHEN LOWER(title) LIKE '%finance%' OR LOWER(title) LIKE '%financial%' OR LOWER(title) LIKE '%accounting%' OR LOWER(title) LIKE '%bookkeep%' OR LOWER(title) LIKE '%audit%' OR LOWER(title) LIKE '%tax%' OR LOWER(title) LIKE '%cpa%' OR LOWER(title) LIKE '%cfa%' THEN 'Finance'
			WHEN LOWER(title) LIKE '%mba%' OR LOWER(title) LIKE '%business%' OR LOWER(title) LIKE '%enterprise%' THEN 'Business'
			WHEN LOWER(title) LIKE '%writing%' OR LOWER(title) LIKE '%screenwriting%' OR LOWER(title) LIKE '%copywriting%' OR LOWER(title) LIKE '%content%' THEN 'Writing'
			WHEN LOWER(title) LIKE '%sales%' OR LOWER(title) LIKE '%marketing%' OR LOWER(title) LIKE '%ppc%' OR LOWER(title) LIKE '%funnel%' THEN 'Sales/Marketing'
			WHEN LOWER(title) LIKE '%data science%' OR LOWER(title) LIKE '%analytics%' OR LOWER(title) LIKE '%machine learning%' OR LOWER(title) LIKE '%ml%' OR LOWER(title) LIKE '%ai%' THEN 'Data Science'
			WHEN LOWER(title) LIKE '%manage%' OR LOWER(title) LIKE '%management%' THEN 'Management'
			WHEN LOWER(title) LIKE '%leadership%' OR LOWER(title) LIKE '%leader%' THEN 'Leadership'
			WHEN LOWER(title) LIKE '%communication%' OR LOWER(title) LIKE '%public speaking%' OR LOWER(title) LIKE '%presentation%' THEN 'Communication'
			ELSE 'Other'
		END AS category
    FROM udemy_courses
) t
GROUP BY category
ORDER BY total_subscribers DESC
LIMIT 5;

-- Best Performing Category (Rating + Subscribers weighted)
SELECT 
    category,
    ROUND(AVG(avg_rating), 2) AS avg_rating,
    SUM(num_subscribers) AS total_subs,
    COUNT(*) AS num_courses
FROM (
    SELECT 
		title, 
		avg_rating, 
        num_subscribers,
        CASE
			WHEN LOWER(title) LIKE '%sql%' OR LOWER(title) LIKE '%mysql%' OR LOWER(title) LIKE '%database%' OR LOWER(title) LIKE '%postgres%' THEN 'Database'
			WHEN LOWER(title) LIKE '%tableau%' OR LOWER(title) LIKE '%power bi%' OR LOWER(title) LIKE '%visualization%' OR LOWER(title) LIKE '%dashboard%' THEN 'Data Visualization'
			WHEN LOWER(title) LIKE '%excel%' OR LOWER(title) LIKE '%spreadsheet%' OR LOWER(title) LIKE '%google sheets%' THEN 'Spreadsheet'
			WHEN LOWER(title) LIKE '%agile%' OR LOWER(title) LIKE '%scrum%' OR LOWER(title) LIKE '%pmp%' OR LOWER(title) LIKE '%project management%' THEN 'Project Management'
			WHEN LOWER(title) LIKE '%finance%' OR LOWER(title) LIKE '%financial%' OR LOWER(title) LIKE '%accounting%' OR LOWER(title) LIKE '%bookkeep%' OR LOWER(title) LIKE '%audit%' OR LOWER(title) LIKE '%tax%' OR LOWER(title) LIKE '%cpa%' OR LOWER(title) LIKE '%cfa%' THEN 'Finance'
			WHEN LOWER(title) LIKE '%mba%' OR LOWER(title) LIKE '%business%' OR LOWER(title) LIKE '%enterprise%' THEN 'Business'
			WHEN LOWER(title) LIKE '%writing%' OR LOWER(title) LIKE '%screenwriting%' OR LOWER(title) LIKE '%copywriting%' OR LOWER(title) LIKE '%content%' THEN 'Writing'
			WHEN LOWER(title) LIKE '%sales%' OR LOWER(title) LIKE '%marketing%' OR LOWER(title) LIKE '%ppc%' OR LOWER(title) LIKE '%funnel%' THEN 'Sales/Marketing'
			WHEN LOWER(title) LIKE '%data science%' OR LOWER(title) LIKE '%analytics%' OR LOWER(title) LIKE '%machine learning%' OR LOWER(title) LIKE '%ml%' OR LOWER(title) LIKE '%ai%' THEN 'Data Science'
			WHEN LOWER(title) LIKE '%manage%' OR LOWER(title) LIKE '%management%' THEN 'Management'
			WHEN LOWER(title) LIKE '%leadership%' OR LOWER(title) LIKE '%leader%' THEN 'Leadership'
			WHEN LOWER(title) LIKE '%communication%' OR LOWER(title) LIKE '%public speaking%' OR LOWER(title) LIKE '%presentation%' THEN 'Communication'
			ELSE 'Other'
		END AS category

    FROM udemy_courses
) t
GROUP BY category
ORDER BY (AVG(avg_rating) * 0.4 + LOG(SUM(num_subscribers)) * 0.6) DESC;

-- 11. High performers: Top 5% courses by subscribers			
WITH ranked_courses AS (
    SELECT
        title,
        num_subscribers,
        avg_rating,
        num_published_lectures,
        discounted_price_amount,
        PERCENT_RANK() OVER (ORDER BY num_subscribers) AS subscriber_percentile
    FROM udemy_courses
)
SELECT
    title,
    num_subscribers,
    avg_rating,
    num_published_lectures,
    discounted_price_amount
FROM ranked_courses
WHERE subscriber_percentile >= 0.95
ORDER BY num_subscribers DESC;

-- =============================================
-- Phase 7: Insight & Value Analysis
-- =============================================
-- 12. Best value courses (high rating, low price, decent subs)
SELECT 
    title,
    avg_rating,
    discounted_price_amount,
    num_subscribers,
    num_reviews
FROM udemy_courses 
WHERE avg_rating >= 4.5 
  AND discounted_price_amount <= 500 
  AND num_subscribers >= 1000
ORDER BY num_subscribers DESC 
LIMIT 20;

-- 13. Underperformers (many lectures, few subscribers)
SELECT 
    title,
    num_published_lectures,
    num_subscribers,
    avg_rating
FROM udemy_courses 
WHERE num_published_lectures > 100 
  AND num_subscribers < 100
ORDER BY num_published_lectures DESC 
LIMIT 10;

-- 14. Executive summary
SELECT 
    'Total Courses' AS metric, COUNT(*) AS value FROM udemy_courses
UNION ALL
SELECT 'Avg Rating', ROUND(AVG(avg_rating), 2) FROM udemy_courses
UNION ALL
SELECT 'Avg Subscribers', ROUND(AVG(num_subscribers), 0) FROM udemy_courses
UNION ALL
SELECT '% Paid Courses', ROUND((SUM(is_paid)/COUNT(*))*100, 1) FROM udemy_courses
UNION ALL
SELECT 'Avg Lectures', ROUND(AVG(num_published_lectures), 0) FROM udemy_courses;

-- 15. Courses by year (trending analysis)
SELECT 
    YEAR(created_date) AS year_created,
    COUNT(*) AS courses_launched,
    AVG(num_subscribers) AS avg_popularity,
    AVG(avg_rating) AS avg_rating
FROM udemy_courses 
GROUP BY YEAR(created_date)
ORDER BY year_created;

-- Growth Analysis
-- 1. Courses per year
SELECT 
    YEAR(STR_TO_DATE(published_time, '%d-%m-%Y')) AS year,
    COUNT(*) AS num_courses_published,
    ROUND(AVG(num_reviews), 0) AS avg_reviews
FROM udemy_courses 
GROUP BY YEAR(STR_TO_DATE(published_time, '%d-%m-%Y'))
ORDER BY year;

-- 2. Year-over-year growth %
WITH yearly_stats AS (
    SELECT 
        YEAR(STR_TO_DATE(published_time, '%d-%m-%Y')) AS year,
        COUNT(*) AS num_courses
    FROM udemy_courses 
    GROUP BY 1
)
SELECT 
    year,
    num_courses,
    LAG(num_courses) OVER (ORDER BY year) AS prev_year,
    ROUND(((num_courses - LAG(num_courses) OVER (ORDER BY year)) / LAG(num_courses) OVER (ORDER BY year)) * 100, 0) AS growth_pct
FROM yearly_stats 
ORDER BY year;

-- Number of Courses and Average Number of Reviews by Category
SELECT 
    CASE 
        WHEN LOWER(title) LIKE '%finance%' OR LOWER(title) LIKE '%accounting%' 
          OR LOWER(title) LIKE '%bookkeep%' OR LOWER(title) LIKE '%audit%' 
          OR LOWER(title) LIKE '%tax%' OR LOWER(title) LIKE '%cpa%' 
          OR LOWER(title) LIKE '%cma%' OR LOWER(title) LIKE '%cfa%' 
        THEN 'Finance/Accounting'
        WHEN LOWER(title) LIKE '%business%' OR LOWER(title) LIKE '%entrepreneur%' 
          OR LOWER(title) LIKE '%startup%' OR LOWER(title) LIKE '%management%' 
          OR LOWER(title) LIKE '%marketing%' OR LOWER(title) LIKE '%sales%' 
          OR LOWER(title) LIKE '%leadership%'
        THEN 'Business/Management'
        ELSE 'Other'
    END AS category,
    COUNT(*) AS num_courses,
    ROUND(AVG(num_reviews), 2) AS avg_reviews
FROM udemy_courses 
GROUP BY 1
ORDER BY num_courses DESC;

-- =====================================================
-- PHASE 8: EXPORT FOR REPORTING & VISUALIZATION
-- =====================================================
-- 1. EXECUTIVE SUMMARY (Single table for dashboard)
SELECT 'Total Courses' AS metric, CAST(COUNT(*) AS CHAR) AS value, '' AS notes FROM udemy_courses
UNION ALL
SELECT 'Courses Published', CAST(COUNT(DISTINCT id) AS CHAR), '' FROM udemy_courses  
UNION ALL
SELECT 'Paid Courses %', CAST(ROUND((SUM(is_paid)/COUNT(*))*100,1) AS CHAR), '' FROM udemy_courses
UNION ALL
SELECT 'Avg Subscribers', CAST(ROUND(AVG(num_subscribers),0) AS CHAR), '' FROM udemy_courses
UNION ALL
SELECT 'Avg Reviews', CAST(ROUND(AVG(num_reviews),0) AS CHAR), '' FROM udemy_courses
UNION ALL
SELECT 'Avg Lectures', CAST(ROUND(AVG(num_published_lectures),0) AS CHAR), '' FROM udemy_courses
UNION ALL
SELECT 'Top Category by Subs', (
    SELECT category
    FROM (
        SELECT 
            CASE
                WHEN LOWER(title) RLIKE 'sql|mysql|database|postgres' THEN 'Database'
                WHEN LOWER(title) RLIKE 'tableau|power bi|visuali|dashboard' THEN 'Data Visualization'
                WHEN LOWER(title) RLIKE 'excel|spreadsheet' THEN 'Spreadsheet'
                WHEN LOWER(title) RLIKE 'agile|scrum|pmp|project.*management' THEN 'Project Management'
                WHEN LOWER(title) RLIKE 'finance|financial|accounting|tax|cpa|cfa' THEN 'Finance'
                WHEN LOWER(title) RLIKE 'mba|business' THEN 'Business'
                ELSE 'Other'
            END AS category,
            SUM(num_subscribers) AS total_subs
        FROM udemy_courses 
        GROUP BY 1 
        ORDER BY total_subs DESC 
        LIMIT 1
    ) t
), ''
ORDER BY 1;

-- 2. CATEGORY PERFORMANCE (Tableau-ready)
SELECT 
    CASE
		WHEN LOWER(title) RLIKE 'sql|mysql|database|postgres' THEN 'Database'
		WHEN LOWER(title) RLIKE 'tableau|power bi|visuali|dashboard' THEN 'Data Visualization'
		WHEN LOWER(title) RLIKE 'excel|spreadsheet' THEN 'Spreadsheet'
		WHEN LOWER(title) RLIKE 'agile|scrum|pmp|project.*management' THEN 'Project Management'
		WHEN LOWER(title) RLIKE 'finance|financial|accounting|tax|cpa|cfa' THEN 'Finance'
		WHEN LOWER(title) RLIKE 'mba|business' THEN 'Business'
		ELSE 'Other'
	END AS category,
    COUNT(*) AS num_courses,
    ROUND(AVG(avg_rating), 2) AS avg_rating,
    ROUND(AVG(num_subscribers), 0) AS avg_subscribers,
    ROUND(SUM(num_subscribers), 0) AS total_subscribers,
    ROUND(AVG(num_reviews), 0) AS avg_reviews,
    ROUND(AVG(num_published_lectures), 0) AS avg_lectures
FROM udemy_courses 
GROUP BY 1 
ORDER BY total_subscribers DESC;

-- 3. TOP 10 SUBSCRIBERS (Bar chart)
SELECT 
    ROW_NUMBER() OVER (ORDER BY num_subscribers DESC) AS ranking,
    title,
    num_subscribers,
    ROUND(avg_rating, 2) AS rating,
    discounted_price_amount AS price,
    num_reviews
FROM udemy_courses 
ORDER BY num_subscribers DESC 
LIMIT 10;

-- 4. TOP 10 RATING (Scatter plot)
SELECT 
    ROW_NUMBER() OVER (ORDER BY avg_rating DESC, num_reviews DESC) AS ranking,
    title,
    ROUND(avg_rating, 2) AS rating,
    num_subscribers,
    num_reviews,
    CASE
		WHEN LOWER(title) RLIKE 'sql|mysql|database|postgres' THEN 'Database'
		WHEN LOWER(title) RLIKE 'tableau|power bi|visuali|dashboard' THEN 'Data Visualization'
		WHEN LOWER(title) RLIKE 'excel|spreadsheet' THEN 'Spreadsheet'
		WHEN LOWER(title) RLIKE 'agile|scrum|pmp|project.*management' THEN 'Project Management'
		WHEN LOWER(title) RLIKE 'finance|financial|accounting|tax|cpa|cfa' THEN 'Finance'
		WHEN LOWER(title) RLIKE 'mba|business' THEN 'Business'
		ELSE 'Other'
	END AS category
FROM udemy_courses 
ORDER BY avg_rating DESC, num_reviews DESC 
LIMIT 10;

-- 5. PRICE ANALYSIS (Histogram)
SELECT 
    CASE 
        WHEN discounted_price_amount = 0 THEN 'Free'
        WHEN discounted_price_amount <= 500 THEN '₹1-500'
        WHEN discounted_price_amount <= 1000 THEN '₹501-1000'
        ELSE '₹1000+'
    END AS price_bucket,
    COUNT(*) AS num_courses,
    ROUND(AVG(avg_rating), 2) AS avg_rating,
    ROUND(AVG(num_subscribers), 0) AS avg_subs
FROM udemy_courses
GROUP BY price_bucket
ORDER BY 
    CASE price_bucket
        WHEN 'Free' THEN 1
        WHEN '₹1-500' THEN 2
        WHEN '₹501-1000' THEN 3
        ELSE 4
    END;

-- 6. GROWTH TREND (Line chart)
SELECT 
    YEAR(STR_TO_DATE(published_time, '%d-%m-%Y')) AS year,
    COUNT(*) AS courses_published,
    ROUND(AVG(num_subscribers), 0) AS avg_popularity,
    ROUND(AVG(avg_rating), 2) AS avg_rating
FROM udemy_courses 
GROUP BY 1 
ORDER BY 1;

-- 7. BEST VALUE COURSES (High rating, low price)
SELECT 
    title,
    CASE
		WHEN LOWER(title) RLIKE 'sql|mysql|database|postgres' THEN 'Database'
		WHEN LOWER(title) RLIKE 'tableau|power bi|visuali|dashboard' THEN 'Data Visualization'
		WHEN LOWER(title) RLIKE 'excel|spreadsheet' THEN 'Spreadsheet'
		WHEN LOWER(title) RLIKE 'agile|scrum|pmp|project.*management' THEN 'Project Management'
		WHEN LOWER(title) RLIKE 'finance|financial|accounting|tax|cpa|cfa' THEN 'Finance'
		WHEN LOWER(title) RLIKE 'mba|business' THEN 'Business'
		ELSE 'Other'
	END AS category,
    ROUND(avg_rating, 2) AS rating,
    discounted_price_amount AS price,
    num_subscribers,
    num_reviews
FROM udemy_courses 
WHERE avg_rating >= 4.5 
  AND discounted_price_amount BETWEEN 0 AND 500
  AND num_subscribers >= 1000
ORDER BY num_subscribers DESC 
LIMIT 20;

-- 8. FULL EXPORT (All key metrics by category for advanced viz)
SELECT 
    CASE
		WHEN LOWER(title) RLIKE 'sql|mysql|database|postgres' THEN 'Database'
		WHEN LOWER(title) RLIKE 'tableau|power bi|visuali|dashboard' THEN 'Data Visualization'
		WHEN LOWER(title) RLIKE 'excel|spreadsheet' THEN 'Spreadsheet'
		WHEN LOWER(title) RLIKE 'agile|scrum|pmp|project.*management' THEN 'Project Management'
		WHEN LOWER(title) RLIKE 'finance|financial|accounting|tax|cpa|cfa' THEN 'Finance'
		WHEN LOWER(title) RLIKE 'mba|business' THEN 'Business'
		ELSE 'Other'
	END AS category,
    title,
    ROUND(avg_rating, 2) AS rating,
    num_subscribers,
    num_reviews,
    num_published_lectures,
    discounted_price_amount AS price,
    YEAR(STR_TO_DATE(published_time, '%d-%m-%Y')) AS publish_year,
    is_paid
FROM udemy_courses 
ORDER BY category, num_subscribers DESC;


-- Verify
SHOW VARIABLES LIKE 'secure_file_priv';








