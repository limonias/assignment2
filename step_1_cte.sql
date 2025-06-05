WITH valid_apps AS (
    -- Застосунки з більш ніж 10 відгуками
    SELECT app_id
    FROM apps_reviews
    GROUP BY app_id
    HAVING COUNT(*) > 10
),
similar_reviews AS (
    -- Застосунки з відгуками, схожими на відгуки інших застосунків (однакова оцінка, схожа кількість "корисно")
    SELECT DISTINCT ar1.app_id
    FROM apps_reviews ar1
    JOIN apps_reviews ar2
        ON ar1.review_score = ar2.review_score
        AND ar1.app_id != ar2.app_id
        AND ABS(ar1.helpful_count - ar2.helpful_count) <= 10
),
varied_texts AS (
    -- Застосунки з відгуками схожої довжини, але різним змістом
    SELECT DISTINCT ar1.app_id
    FROM apps_reviews ar1
    JOIN apps_reviews ar2
        ON ar1.app_id = ar2.app_id
        AND ar1.review_text != ar2.review_text
        AND ABS(LENGTH(ar1.review_text) - LENGTH(ar2.review_text)) <= 50
),
monthly_scores AS (
    -- Застосунки з кількома відгуками однакової оцінки в одному місяці
    SELECT DISTINCT app_id
    FROM apps_reviews
    GROUP BY app_id, review_score, YEAR(review_date), MONTH(review_date)
    HAVING COUNT(*) > 1
),
positive_reviews AS (
    -- Застосунки з мінімум 5 позитивними відгуками (оцінка >= 3)
    SELECT app_id
    FROM apps_reviews
    WHERE review_score >= 3
    GROUP BY app_id
    HAVING COUNT(*) >= 5
)

-- Основний запит з CTE
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
    AND ar.review_date >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
    AND LENGTH(ar.review_text) >= 10
    AND ar.app_id IN (SELECT app_id FROM positive_reviews);
