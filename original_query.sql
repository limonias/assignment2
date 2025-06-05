SELECT 
    ar1.app_id,         -- Ідентифікатор застосунку
    ar1.review_text,    -- Текст відгуку
    ar1.review_score,   -- Оцінка, поставлена користувачем
    ar1.review_date,    -- Дата публікації відгуку
    ar1.helpful_count   -- Кількість позначок "корисно" для відгуку
FROM apps_reviews ar1

-- Вибираємо лише ті застосунки, які мають більше 10 відгуків
INNER JOIN (
    SELECT app_id
    FROM apps_reviews 
    GROUP BY app_id
    HAVING COUNT(*) > 10
) AS valid_apps ON ar1.app_id = valid_apps.app_id

-- Шукаємо застосунки, у яких є відгуки, схожі на відгуки інших застосунків
-- (однакова оцінка та схожа кількість "корисно", але різні app_id)
LEFT JOIN (
    SELECT DISTINCT ar1.app_id
    FROM apps_reviews ar1
    JOIN apps_reviews ar2 
        ON ar1.review_score = ar2.review_score
        AND ar1.app_id != ar2.app_id
        AND ABS(ar1.helpful_count - ar2.helpful_count) <= 10
) AS similar_reviews ON ar1.app_id = similar_reviews.app_id

-- Шукаємо застосунки, де є відгуки з однаковою довжиною (±50 символів),
-- але з різним текстом
LEFT JOIN (
    SELECT DISTINCT ar1.app_id
    FROM apps_reviews ar1
    JOIN apps_reviews ar2 
        ON ar1.app_id = ar2.app_id
        AND ar1.review_text != ar2.review_text
        AND ABS(LENGTH(ar1.review_text) - LENGTH(ar2.review_text)) <= 50
) AS varied_texts ON ar1.app_id = varied_texts.app_id

-- Визначаємо застосунки, у яких за один місяць є кілька однакових оцінок
LEFT JOIN (
    SELECT DISTINCT app_id
    FROM apps_reviews
    GROUP BY app_id, review_score, YEAR(review_date), MONTH(review_date)
    HAVING COUNT(*) > 1
) AS monthly_scores ON ar1.app_id = monthly_scores.app_id

-- Фільтруємо відгуки за такими умовами:
-- - оцінка не менше 3
-- - кількість "корисно" не менше 0
-- - дата не старіша за 2 роки
-- - текст має не менше 10 символів
-- - застосунок має щонайменше 5 позитивних (оцінка ≥3) відгуків
WHERE 
    ar1.review_score >= 3
    AND ar1.helpful_count >= 0
    AND ar1.review_date >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
    AND LENGTH(ar1.review_text) >= 10
    AND ar1.app_id IN (
        SELECT app_id
        FROM apps_reviews
        WHERE review_score >= 3
        GROUP BY app_id
        HAVING COUNT(*) >= 5
);
