import { useState, useEffect } from "react";
import { useAuth } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import AppHeader from "@/components/AppHeader";
import { useToast } from "@/hooks/use-toast";
import { BookPlus, Filter, Loader2 } from "lucide-react";

interface Materia {
  id: string; codigo: string; nombre: string; creditos: number;
  horario: string; cupos_totales: number; cupos_disponibles: number;
  semestre: number; carrera_id: string;
}

export default function Catalog() {
  const { profile } = useAuth();
  const { toast } = useToast();
  const [semestre, setSemestre] = useState<string>("user");
  const [subjects, setSubjects] = useState<Materia[]>([]);
  const [enrolledIds, setEnrolledIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [enrolling, setEnrolling] = useState<string | null>(null);

  const fetchData = async () => {
    if (!profile) return;
    setLoading(true);

    let query = supabase.from("materias").select("*").eq("carrera_id", profile.carrera_id);
    if (semestre !== "all") {
      const sem = semestre === "user" ? profile.semestre_actual : parseInt(semestre);
      query = query.eq("semestre", sem);
    }

    const [{ data: materias }, { data: inscripciones }] = await Promise.all([
      query.order("semestre").order("codigo"),
      supabase.from("inscripciones").select("materia_id").eq("usuario_id", profile.id).eq("estado", "inscrita"),
    ]);

    setSubjects((materias || []) as Materia[]);
    setEnrolledIds(new Set((inscripciones || []).map(i => i.materia_id)));
    setLoading(false);
  };

  useEffect(() => { fetchData(); }, [profile, semestre]);

  const handleEnroll = async (materiaId: string) => {
    if (!profile) return;
    setEnrolling(materiaId);
    const { data, error } = await supabase.rpc("inscribir_materia", {
      p_usuario_id: profile.id,
      p_materia_id: materiaId,
    });
    setEnrolling(null);

    const result = data as any;
    toast({
      title: result?.success ? "¡Inscrito!" : "Error",
      description: result?.message || error?.message || "Error desconocido",
      variant: result?.success ? "default" : "destructive",
    });
    if (result?.success) fetchData();
  };

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="container py-8">
        <div className="mb-6 animate-fade-in">
          <h1 className="font-display text-2xl font-bold text-foreground">Catálogo de Materias</h1>
          <p className="text-muted-foreground text-sm mt-1">Materias de tu carrera: {profile?.carrera_nombre}</p>
        </div>

        <Card className="glass-card mb-6 animate-fade-in" style={{ animationDelay: "100ms" }}>
          <CardHeader className="pb-3">
            <CardTitle className="font-display text-base flex items-center gap-2">
              <Filter className="h-4 w-4" /> Filtros
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="w-full sm:w-48">
              <Select value={semestre} onValueChange={setSemestre}>
                <SelectTrigger><SelectValue placeholder="Semestre" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="user">Mi semestre ({profile?.semestre_actual})</SelectItem>
                  <SelectItem value="all">Todos</SelectItem>
                  {[1,2,3,4,5,6,7,8,9,10].map((s) => (
                    <SelectItem key={s} value={s.toString()}>Semestre {s}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {loading ? (
          <div className="flex justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
        ) : subjects.length === 0 ? (
          <Card className="glass-card animate-fade-in">
            <CardContent className="py-12 text-center text-muted-foreground">
              No hay materias para estos filtros
            </CardContent>
          </Card>
        ) : (
          <Card className="glass-card animate-fade-in overflow-hidden" style={{ animationDelay: "200ms" }}>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Código</TableHead>
                    <TableHead>Nombre</TableHead>
                    <TableHead className="text-center">Créditos</TableHead>
                    <TableHead>Horario</TableHead>
                    <TableHead className="text-center">Cupos</TableHead>
                    <TableHead className="text-center">Estado</TableHead>
                    <TableHead className="text-center">Acción</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {subjects.map((s) => {
                    const isEnrolled = enrolledIds.has(s.id);
                    const noSlots = s.cupos_disponibles === 0;
                    return (
                      <TableRow key={s.id}>
                        <TableCell className="font-mono text-xs">{s.codigo}</TableCell>
                        <TableCell className="font-medium">{s.nombre}</TableCell>
                        <TableCell className="text-center">{s.creditos}</TableCell>
                        <TableCell className="text-sm">{s.horario}</TableCell>
                        <TableCell className="text-center">{s.cupos_disponibles}/{s.cupos_totales}</TableCell>
                        <TableCell className="text-center">
                          {isEnrolled ? (
                            <Badge className="bg-primary/10 text-primary border-0">Inscrito</Badge>
                          ) : noSlots ? (
                            <Badge variant="destructive">Sin cupos</Badge>
                          ) : (
                            <Badge className="bg-accent text-accent-foreground border-0">Disponible</Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-center">
                          <Button
                            size="sm"
                            onClick={() => handleEnroll(s.id)}
                            disabled={isEnrolled || noSlots || enrolling === s.id}
                            className="gap-1"
                          >
                            {enrolling === s.id ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <BookPlus className="h-3.5 w-3.5" />}
                            Inscribir
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          </Card>
        )}
      </main>
    </div>
  );
}
