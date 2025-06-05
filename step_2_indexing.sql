CREATE INDEX idx_main ON apps_reviews (review_score, helpful_count, review_date, app_id);
CREATE INDEX idx_positive_reviews ON apps_reviews (app_id, review_score);
CREATE INDEX idx_similar_reviews ON apps_reviews (review_score, helpful_count, app_id);
CREATE INDEX idx_varied_text ON apps_reviews (app_id,review_text(100));

EXPLAIN ANALYZE  
WITH valid_apps AS (
    SELECT app_id
    FROM apps_reviews
    GROUP BY app_id
    HAVING COUNT(*) > 10
),

similar_reviews AS (
    SELECT DISTINCT ar1.app_id
    FROM apps_reviews ar1 USE INDEX (idx_similar_reviews)
    JOIN apps_reviews ar2
        ON ar1.review_score = ar2.review_score
        AND ABS(ar1.helpful_count - ar2.helpful_count) <= 10
        AND ar1.app_id != ar2.app_id
        
),
varied_texts AS (
    SELECT DISTINCT ar1.app_id
    FROM apps_reviews ar1
    JOIN apps_reviews ar2
        ON ar1.app_id = ar2.app_id
        AND ar1.review_text != ar2.review_text
        AND ABS(LENGTH(ar1.review_text) - LENGTH(ar2.review_text)) <= 50
),
monthly_scores AS (
    SELECT DISTINCT app_id
    FROM apps_reviews
    GROUP BY app_id, review_score, YEAR(review_date), MONTH(review_date)
    HAVING COUNT(*) > 1
),
positive_reviews AS (
    SELECT app_id
    FROM apps_reviews
    WHERE review_score >= 3
    GROUP BY app_id
    HAVING COUNT(*) >= 5
)
SELECT 
    ar.app_id,
    ar.review_text,
    ar.review_score,
    ar.review_date,
    ar.helpful_count
FROM apps_reviews ar 
JOIN valid_apps va ON ar.app_id = va.app_id
LEFT JOIN similar_reviews sr ON ar.app_id = sr.app_id
LEFT JOIN varied_texts vt ON ar.app_id = vt.app_id
LEFT JOIN monthly_scores ms ON ar.app_id = ms.app_id
WHERE 
    ar.review_score >= 3
    AND ar.helpful_count >= 0
    AND ar.review_date >= CURDATE() - INTERVAL 2 YEAR
    AND LENGTH(ar.review_text) >= 10
    AND ar.app_id IN (SELECT app_id FROM positive_reviews);