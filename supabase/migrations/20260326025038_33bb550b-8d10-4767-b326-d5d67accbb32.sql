-- Refuerza la cancelación para que use el usuario autenticado real,
-- valide filas afectadas y mantenga RLS completo en inscripciones.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'inscripciones'
      AND policyname = 'Users can read own inscripciones'
  ) THEN
    CREATE POLICY "Users can read own inscripciones"
      ON public.inscripciones
      FOR SELECT
      TO authenticated
      USING (usuario_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'inscripciones'
      AND policyname = 'Users can insert own inscripciones'
  ) THEN
    CREATE POLICY "Users can insert own inscripciones"
      ON public.inscripciones
      FOR INSERT
      TO authenticated
      WITH CHECK (usuario_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'inscripciones'
      AND policyname = 'Users can update own inscripciones'
  ) THEN
    CREATE POLICY "Users can update own inscripciones"
      ON public.inscripciones
      FOR UPDATE
      TO authenticated
      USING (usuario_id = auth.uid())
      WITH CHECK (usuario_id = auth.uid());
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.incrementar_cupos(materia_id_input uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.materias
  SET cupos_disponibles = cupos_disponibles + 1
  WHERE id = materia_id_input;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancelar_inscripcion(p_usuario_id uuid, p_materia_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_user_id uuid := auth.uid();
  v_materia_nombre text;
  v_updated_rows integer := 0;
BEGIN
  IF v_auth_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Usuario no autenticado');
  END IF;

  IF p_usuario_id IS NOT NULL AND p_usuario_id <> v_auth_user_id THEN
    RETURN json_build_object('success', false, 'message', 'No autorizado para cancelar esta inscripción');
  END IF;

  SELECT nombre INTO v_materia_nombre
  FROM public.materias
  WHERE id = p_materia_id;

  IF v_materia_nombre IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Materia no encontrada');
  END IF;

  UPDATE public.inscripciones
  SET estado = 'cancelada'
  WHERE usuario_id = v_auth_user_id
    AND materia_id = p_materia_id
    AND estado = 'inscrita';

  GET DIAGNOSTICS v_updated_rows = ROW_COUNT;

  IF v_updated_rows = 0 THEN
    RETURN json_build_object('success', false, 'message', 'No estás inscrito en esta materia');
  END IF;

  PERFORM public.incrementar_cupos(p_materia_id);

  RETURN json_build_object('success', true, 'message', format('Materia %s cancelada exitosamente', v_materia_nombre));
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'message', SQLERRM);
END;
$$;