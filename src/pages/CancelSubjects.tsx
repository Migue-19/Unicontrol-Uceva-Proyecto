import { useState, useEffect } from "react";
import { useAuth, UserProfile } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";  
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import AppHeader from "@/components/AppHeader";
import { useToast } from "@/hooks/use-toast";
import { Trash2, XCircle, Loader2 } from "lucide-react";

interface EnrolledSubject {
  id: string;
  materia_id: string;
  codigo: string;
  nombre: string;
  creditos: number;
  horario: string;
}

interface CancellationResult {
  success?: boolean;
  message?: string;
}

export default function CancelSubjects() {
  const { profile } = useAuth();
  const { toast } = useToast();
  const [enrolled, setEnrolled] = useState<EnrolledSubject[]>([]);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState<string | null>(null);

  const fetchEnrolled = async (
    { throwOnError = false, currentProfile }: { throwOnError?: boolean; currentProfile?: UserProfile | null } = {}
  ): Promise<EnrolledSubject[]> => {
    const p = currentProfile ?? profile;
    if (!p) {
      setEnrolled([]);
      setLoading(false);
      return [];
    }

    setLoading(true);

    try {  
      const { data, error } = await supabase
        .from("inscripciones")
        .select("id, materia_id, materias(codigo, nombre, creditos, horario)")
        .eq("usuario_id", p.id)
        .eq("estado", "inscrita");

      if (error) {
        console.error("Error consultando inscripciones activas:", error);
        throw error;
      }

      const mapped = (data || []).map((d) => ({
        id: d.id,
        materia_id: d.materia_id,
        codigo: (d.materias as any)?.codigo || "",
        nombre: (d.materias as any)?.nombre || "",
        creditos: (d.materias as any)?.creditos || 0,
        horario: (d.materias as any)?.horario || "",
      }));

      setEnrolled(mapped);
      return mapped;
    } catch (error) {
      console.error("[CancelSubjects] fetchEnrolled error:", error);
      setEnrolled([]);

      if (throwOnError) {
        throw error;
      }

      toast({
        title: "Error al cargar materias",
        description: "No fue posible sincronizar tus materias desde Supabase.",
        variant: "destructive",
      });

      return [];
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchEnrolled();
  }, [profile]);

  const handleCancel = async (materiaId: string) => {
    if (!profile) return;

    setCancelling(materiaId);

    try {
      console.log("[CancelSubjects] Cancelando materia:", materiaId, "usuario:", profile.id);

      const { data, error } = await supabase.rpc("cancelar_inscripcion", {
        p_usuario_id: profile.id,
        p_materia_id: materiaId,
      });

      if (error) {
        console.error("[CancelSubjects] RPC error:", error);
        throw error;
      }

      const result = data as CancellationResult | null;
      console.log("[CancelSubjects] RPC result:", result);

      if (!result?.success) {
        throw new Error(result?.message || "La cancelación no pudo completarse.");
      }

      // Verify directly in DB that row is no longer 'inscrita'
      const { data: verifyData, error: verifyError } = await supabase
        .from("inscripciones")
        .select("id, estado")
        .eq("usuario_id", profile.id)
        .eq("materia_id", materiaId)
        .eq("estado", "inscrita");

      console.log("[CancelSubjects] Verification query:", { verifyData, verifyError });

      if (verifyError) {
        console.error("[CancelSubjects] Verification error:", verifyError);
      }

      if (verifyData && verifyData.length > 0) {
        // RPC said success but row still inscrita — try direct update as fallback
        console.warn("[CancelSubjects] Row still inscrita, attempting direct update fallback");
        const { error: directError } = await supabase
          .from("inscripciones")
          .update({ estado: "cancelada" })
          .eq("usuario_id", profile.id)
          .eq("materia_id", materiaId)
          .eq("estado", "inscrita");

        if (directError) {
          console.error("[CancelSubjects] Direct update failed:", directError);
          throw new Error("La cancelación no se reflejó en la base de datos.");
        }

        // Also increment cupos via helper
        await supabase.rpc("incrementar_cupos", { materia_id_input: materiaId });
      }

      // Refresh the list
      await fetchEnrolled();

      toast({
        title: "Materia cancelada correctamente",
        description: result.message || "La materia fue actualizada en Supabase.",
      });
    } catch (error) {
      console.error("[CancelSubjects] handleCancel error:", error);
      toast({
        title: "Error al cancelar materia",
        description: error instanceof Error ? error.message : "Error desconocido",
        variant: "destructive",
      });
    } finally {
      setCancelling(null);
    }
  };

  if (!profile) return null;

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="container py-8">
        <div className="mb-6 animate-fade-in">
          <h1 className="font-display text-2xl font-bold text-foreground flex items-center gap-2">
            <XCircle className="h-7 w-7 text-destructive" /> Cancelar Materias
          </h1>
          <p className="text-muted-foreground text-sm mt-1">Selecciona las materias que deseas cancelar. Los cupos se liberan automáticamente.</p>
        </div>

        {loading ? (
          <div className="flex justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
        ) : enrolled.length === 0 ? (
          <Card className="glass-card animate-fade-in">
            <CardContent className="py-12 text-center text-muted-foreground">
              No tienes materias inscritas para cancelar.
            </CardContent>
          </Card>
        ) : (
          <Card className="glass-card overflow-hidden animate-fade-in" style={{ animationDelay: "100ms" }}>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Código</TableHead>
                    <TableHead>Nombre</TableHead>
                    <TableHead className="text-center">Créditos</TableHead>
                    <TableHead>Horario</TableHead>
                    <TableHead className="text-center">Acción</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {enrolled.map((e) => (
                    <TableRow key={e.id}>
                      <TableCell className="font-mono text-xs">{e.codigo}</TableCell>
                      <TableCell className="font-medium">{e.nombre}</TableCell>
                      <TableCell className="text-center">{e.creditos}</TableCell>
                      <TableCell className="text-sm">{e.horario}</TableCell>
                      <TableCell className="text-center">
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => handleCancel(e.materia_id)}
                          disabled={cancelling === e.materia_id}
                          className="gap-1"
                        >
                          {cancelling === e.materia_id ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Trash2 className="h-3.5 w-3.5" />}
                          Cancelar
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </Card>
        )}
      </main>
    </div>
  );
}
