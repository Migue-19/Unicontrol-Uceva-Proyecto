
-- 1. Facultades
CREATE TABLE public.facultades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL UNIQUE
);

-- 2. Carreras
CREATE TABLE public.carreras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  facultad_id UUID REFERENCES public.facultades(id) ON DELETE CASCADE NOT NULL
);

-- 3. Usuarios (profiles)
CREATE TABLE public.usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  codigo_estudiantil TEXT NOT NULL UNIQUE,
  carrera_id UUID REFERENCES public.carreras(id) NOT NULL,
  semestre_actual INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Materias
CREATE TABLE public.materias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  creditos INT NOT NULL,
  carrera_id UUID REFERENCES public.carreras(id) ON DELETE CASCADE NOT NULL,
  semestre INT NOT NULL,
  cupos_totales INT NOT NULL DEFAULT 35,
  cupos_disponibles INT NOT NULL DEFAULT 35,
  horario TEXT NOT NULL
);

-- 5. Inscripciones
CREATE TABLE public.inscripciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE NOT NULL,
  materia_id UUID REFERENCES public.materias(id) ON DELETE CASCADE NOT NULL,
  estado TEXT NOT NULL DEFAULT 'inscrita',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(usuario_id, materia_id)
);

-- RLS
ALTER TABLE public.facultades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carreras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inscripciones ENABLE ROW LEVEL SECURITY;

-- Facultades: anyone authenticated can read
CREATE POLICY "Authenticated can read facultades" ON public.facultades FOR SELECT TO authenticated USING (true);

-- Carreras: anyone authenticated can read
CREATE POLICY "Authenticated can read carreras" ON public.carreras FOR SELECT TO authenticated USING (true);

-- Also allow anon to read facultades and carreras (for registration form)
CREATE POLICY "Anon can read facultades" ON public.facultades FOR SELECT TO anon USING (true);
CREATE POLICY "Anon can read carreras" ON public.carreras FOR SELECT TO anon USING (true);

-- Usuarios: user can read/insert/update own profile
CREATE POLICY "Users can read own profile" ON public.usuarios FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "Users can insert own profile" ON public.usuarios FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
CREATE POLICY "Users can update own profile" ON public.usuarios FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Materias: authenticated can read all
CREATE POLICY "Authenticated can read materias" ON public.materias FOR SELECT TO authenticated USING (true);

-- Inscripciones: user manages own
CREATE POLICY "Users can read own inscripciones" ON public.inscripciones FOR SELECT TO authenticated USING (usuario_id = auth.uid());
CREATE POLICY "Users can insert own inscripciones" ON public.inscripciones FOR INSERT TO authenticated WITH CHECK (usuario_id = auth.uid());
CREATE POLICY "Users can update own inscripciones" ON public.inscripciones FOR UPDATE TO authenticated USING (usuario_id = auth.uid()) WITH CHECK (usuario_id = auth.uid());

-- Function to decrement cupos on enrollment
CREATE OR REPLACE FUNCTION public.inscribir_materia(p_usuario_id UUID, p_materia_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_materia materias%ROWTYPE;
  v_creditos_actuales INT;
  v_conflicto TEXT;
  v_resultado JSON;
BEGIN
  -- Get materia
  SELECT * INTO v_materia FROM materias WHERE id = p_materia_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'Materia no encontrada');
  END IF;

  -- Check cupos
  IF v_materia.cupos_disponibles <= 0 THEN
    RETURN json_build_object('success', false, 'message', 'No hay cupos disponibles');
  END IF;

  -- Check duplicate
  IF EXISTS (SELECT 1 FROM inscripciones WHERE usuario_id = p_usuario_id AND materia_id = p_materia_id AND estado = 'inscrita') THEN
    RETURN json_build_object('success', false, 'message', 'Ya estás inscrito en esta materia');
  END IF;

  -- Check max credits
  SELECT COALESCE(SUM(m.creditos), 0) INTO v_creditos_actuales
  FROM inscripciones i JOIN materias m ON i.materia_id = m.id
  WHERE i.usuario_id = p_usuario_id AND i.estado = 'inscrita';

  IF v_creditos_actuales + v_materia.creditos > 21 THEN
    RETURN json_build_object('success', false, 'message',
      format('Excede el máximo de 21 créditos (actual: %s, intentando agregar: %s)', v_creditos_actuales, v_materia.creditos));
  END IF;

  -- Check schedule conflict
  SELECT m.nombre INTO v_conflicto
  FROM inscripciones i JOIN materias m ON i.materia_id = m.id
  WHERE i.usuario_id = p_usuario_id AND i.estado = 'inscrita' AND m.horario = v_materia.horario
  LIMIT 1;

  IF v_conflicto IS NOT NULL THEN
    RETURN json_build_object('success', false, 'message', format('Conflicto de horario con %s', v_conflicto));
  END IF;

  -- Enroll
  INSERT INTO inscripciones (usuario_id, materia_id, estado) VALUES (p_usuario_id, p_materia_id, 'inscrita');
  UPDATE materias SET cupos_disponibles = cupos_disponibles - 1 WHERE id = p_materia_id;

  RETURN json_build_object('success', true, 'message', format('Inscrito exitosamente en %s', v_materia.nombre));
END;
$$;

-- Function to cancel enrollment
CREATE OR REPLACE FUNCTION public.cancelar_inscripcion(p_usuario_id UUID, p_materia_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_materia_nombre TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inscripciones WHERE usuario_id = p_usuario_id AND materia_id = p_materia_id AND estado = 'inscrita') THEN
    RETURN json_build_object('success', false, 'message', 'No estás inscrito en esta materia');
  END IF;

  SELECT nombre INTO v_materia_nombre FROM materias WHERE id = p_materia_id;

  UPDATE inscripciones SET estado = 'cancelada' WHERE usuario_id = p_usuario_id AND materia_id = p_materia_id AND estado = 'inscrita';
  UPDATE materias SET cupos_disponibles = cupos_disponibles + 1 WHERE id = p_materia_id;

  RETURN json_build_object('success', true, 'message', format('Materia %s cancelada exitosamente', v_materia_nombre));
END;
$$;
