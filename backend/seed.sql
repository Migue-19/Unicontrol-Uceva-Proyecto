-- SEED de Pruebas: Unicontrol (Ficticio para testing)

-- Limpiar tablas base (CUIDADO: Borrará datos si los hay)
TRUNCATE TABLE inscripciones, cargas_academicas CASCADE;
TRUNCATE TABLE materias, carreras, facultades CASCADE;

-- Insertar Facultades
INSERT INTO facultades (nombre) VALUES 
  ('Ingeniería'),
  ('Ciencias de la Salud'),
  ('Ciencias Administrativas')
RETURNING id;
-- (Esquivaremos depender de los IDs generados haciendo subqueries simples)

-- Insertar Carreras
INSERT INTO carreras (nombre, facultad_id) VALUES 
  ('Ingeniería de Sistemas', (SELECT id FROM facultades WHERE nombre = 'Ingeniería' LIMIT 1)),
  ('Ingeniería Industrial', (SELECT id FROM facultades WHERE nombre = 'Ingeniería' LIMIT 1)),
  ('Medicina', (SELECT id FROM facultades WHERE nombre = 'Ciencias de la Salud' LIMIT 1)),
  ('Enfermería', (SELECT id FROM facultades WHERE nombre = 'Ciencias de la Salud' LIMIT 1)),
  ('Administración de Empresas', (SELECT id FROM facultades WHERE nombre = 'Ciencias Administrativas' LIMIT 1));

-- Insertar Materias
INSERT INTO materias (nombre, codigo, creditos, horario, cupos_totales, cupos_disponibles, semestre) VALUES 
  ('Programación Orientada a Objetos', 'SIS-201', 4, 'Lun 14:00 - 16:00', 30, 30, 2),
  ('Matemáticas Discretas', 'SIS-102', 3, 'Mar 08:00 - 10:00', 30, 30, 1),
  ('Bases de Datos', 'SIS-301', 4, 'Jue 10:00 - 12:00', 25, 25, 3),
  ('Física Mecánica', 'FIS-101', 3, 'Vie 14:00 - 16:00', 40, 40, 1),
  ('Cálculo Integral', 'MAT-201', 4, 'Lun 10:00 - 12:00', 35, 35, 2),
  ('Ingeniería de Software I', 'SIS-401', 3, 'Mié 14:00 - 16:00', 25, 25, 4),
  ('Estructuras de Datos', 'SIS-302', 4, 'Mar 10:00 - 12:00', 30, 30, 3),
  ('Microbiología', 'MED-201', 4, 'Lun 08:00 - 10:00', 20, 20, 2),
  ('Anatomía Funcional', 'MED-101', 5, 'Jue 08:00 - 11:00', 20, 20, 1),
  ('Contabilidad General', 'ADM-101', 3, 'Mié 08:00 - 10:00', 40, 40, 1);
