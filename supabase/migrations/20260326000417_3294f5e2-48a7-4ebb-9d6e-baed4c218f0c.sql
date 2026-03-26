
-- Grant execute on RPC functions to authenticated users
GRANT EXECUTE ON FUNCTION public.inscribir_materia(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancelar_inscripcion(UUID, UUID) TO authenticated;
