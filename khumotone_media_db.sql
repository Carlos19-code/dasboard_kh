-- Banco de dados: KHUMOTONE
-- Armazena apenas documentos e imagens
-- Tamanho estimado: ~85 MB (dentro do limite de 100 MB)

CREATE DATABASE khumotone_media_db;
USE khumotone_media_db;

-- Tabela principal para documentos (35 documentos)
CREATE TABLE documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    document_type VARCHAR(50) NOT NULL, -- 'business-plan', 'procedures', 'loi', 'fco', 'spa', 'copper', 'cobalt'
    document_name VARCHAR(255) NOT NULL,
    language VARCHAR(20) NOT NULL, -- 'portuguese', 'french', 'english', 'spanish', 'mandarin'
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL, -- em bytes
    file_data LONGBLOB NOT NULL, -- Conteúdo do arquivo PDF
    mime_type VARCHAR(100) DEFAULT 'application/pdf',
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    category VARCHAR(50) NOT NULL, -- Categoria para agrupamento
    status ENUM('active', 'inactive') DEFAULT 'active',
    
    -- Índices para otimização
    INDEX idx_document_type (document_type),
    INDEX idx_language (language),
    INDEX idx_category (category),
    INDEX idx_status (status),
    INDEX idx_upload_date (upload_date)
);

-- Tabela para imagens (6 imagens)
CREATE TABLE images (
    id INT PRIMARY KEY AUTO_INCREMENT,
    image_type VARCHAR(50) NOT NULL, -- 'logo-light', 'logo-dark', 'admin-photo', 'portfolio'
    image_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL, -- em bytes
    image_data LONGBLOB NOT NULL, -- Conteúdo da imagem
    mime_type VARCHAR(100) NOT NULL, -- 'image/png', 'image/jpeg', etc.
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    display_order INT DEFAULT 0,
    status ENUM('active', 'inactive') DEFAULT 'active',
    
    -- Índices para otimização
    INDEX idx_image_type (image_type),
    INDEX idx_status (status),
    INDEX idx_display_order (display_order)
);

-- Inserir registros básicos para as imagens do sistema
INSERT INTO images (image_type, image_name, file_size, mime_type, display_order) VALUES
('logo-light', 'logo2.png', 0, 'image/png', 1),
('logo-dark', 'logo3.png', 0, 'image/png', 2),
('admin-photo', 'foto.png', 0, 'image/jpeg', 3),
('portfolio', 'portfolio1.jpg', 0, 'image/jpeg', 4),
('portfolio', 'portfolio2.jpg', 0, 'image/jpeg', 5),
('portfolio', 'portfolio3.jpg', 0, 'image/jpeg', 6);

-- Query para verificar espaço utilizado
SELECT 
    'Documents' as type,
    COUNT(*) as file_count,
    ROUND(SUM(file_size) / 1024 / 1024, 2) as total_size_mb,
    ROUND(AVG(file_size) / 1024 / 1024, 2) as avg_size_mb
FROM documents
UNION ALL
SELECT 
    'Images' as type,
    COUNT(*) as file_count,
    ROUND(SUM(file_size) / 1024 / 1024, 2) as total_size_mb,
    ROUND(AVG(file_size) / 1024 / 1024, 2) as avg_size_mb
FROM images;

-- Query para verificar uso total do banco
SELECT 
    ROUND((
        SELECT SUM(file_size) FROM documents
    ) + (
        SELECT SUM(file_size) FROM images
    ) / 1024 / 1024, 2) as total_database_size_mb;

-- Stored procedure para limpar documentos antigos se necessário
DELIMITER //
CREATE PROCEDURE CleanupOldFiles(IN max_size_mb INT)
BEGIN
    DECLARE current_size_mb DECIMAL(10,2);
    
    -- Calcular tamanho atual
    SELECT ROUND((
        SELECT IFNULL(SUM(file_size), 0) FROM documents
    ) + (
        SELECT IFNULL(SUM(file_size), 0) FROM images
    ) / 1024 / 1024, 2) INTO current_size_mb;
    
    -- Se ultrapassar o limite, remover arquivos mais antigos
    IF current_size_mb > max_size_mb THEN
        -- Primeiro, desativar documentos mais antigos
        UPDATE documents 
        SET status = 'inactive' 
        WHERE status = 'active' 
        ORDER BY upload_date ASC 
        LIMIT 5;
        
        -- Depois, desativar imagens mais antigas (exceto logos essenciais)
        UPDATE images 
        SET status = 'inactive' 
        WHERE status = 'active' 
        AND image_type = 'portfolio'
        ORDER BY upload_date ASC 
        LIMIT 2;
    END IF;
END //
DELIMITER ;

-- View para relatório simples de arquivos
CREATE VIEW media_files_report AS
SELECT 
    'document' as file_type,
    document_name as name,
    file_size,
    upload_date,
    status
FROM documents
UNION ALL
SELECT 
    'image' as file_type,
    image_name as name,
    file_size,
    upload_date,
    status
FROM images
ORDER BY upload_date DESC;