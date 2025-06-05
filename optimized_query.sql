CREATE INDEX idx_main ON apps_reviews (app_id, review_score, helpful_count, review_date, review_text(100));

WITH valid_apps AS (
    SELECT app_id
    FROM apps_reviews
    GROUP BY app_id
    HAVING COUNT(*) > 10
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
FROM apps_reviews ar USE INDEX (idx_main)
JOIN valid_apps va ON ar.app_id = va.app_id
JOIN positive_reviews pr ON ar.app_id = pr.app_id
WHERE 
    ar.review_score >= 3
    AND ar.helpful_count >= 0
    AND ar.review_date >= CURDATE() - INTERVAL 2 YEAR
    AND LENGTH(ar.review_text) >= 10;