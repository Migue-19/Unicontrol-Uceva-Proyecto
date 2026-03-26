import { useEffect, useState } from "react";
import { useAuth } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import AppHeader from "@/components/AppHeader";
import { useNavigate } from "react-router-dom";
import { LogOut, RefreshCw, User } from "lucide-react";

export default function Profile() {
  const { profile, logout, markTutorialSeen } = useAuth();
  const navigate = useNavigate();
  const [totalCredits, setTotalCredits] = useState(0);
  const [enrolledCount, setEnrolledCount] = useState(0);

  useEffect(() => {
    if (!profile) return;
    supabase
      .from("inscripciones")
      .select("materia_id, materias(creditos)")
      .eq("usuario_id", profile.id)
      .eq("estado", "inscrita")
      .then(({ data }) => {
        if (data) {
          setEnrolledCount(data.length);
          setTotalCredits(data.reduce((s, d) => s + ((d.materias as any)?.creditos || 0), 0));
        }
      });
  }, [profile]);

  if (!profile) return null;

  const handleLogout = async () => {
    await logout();
    navigate("/login");
  };

  const restartTutorial = async () => {
    // Reset tutorial_visto in DB so tutorial shows again
    if (profile) {
      await supabase.from("usuarios").update({ tutorial_visto: false } as any).eq("id", profile.id);
    }
    navigate("/dashboard");
    window.location.reload();
  };

  const fields = [
    { label: "Nombre", value: profile.nombre },
    { label: "Código", value: profile.codigo_estudiantil },
    { label: "Correo", value: profile.email },
    { label: "Carrera", value: profile.carrera_nombre || "" },
    { label: "Semestre", value: `${profile.semestre_actual}` },
    { label: "Materias inscritas", value: `${enrolledCount}` },
    { label: "Créditos", value: `${totalCredits} / 21` },
  ];

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="container py-8 max-w-lg">
        <div className="mb-6 animate-fade-in">
          <h1 className="font-display text-2xl font-bold text-foreground flex items-center gap-2">
            <User className="h-7 w-7 text-primary" /> Mi Perfil
          </h1>
        </div>

        <Card className="glass-card animate-fade-in" style={{ animationDelay: "100ms" }}>
          <CardHeader>
            <CardTitle className="font-display">Datos Personales</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {fields.map((f) => (
              <div key={f.label} className="flex justify-between items-center py-2 border-b border-border last:border-0">
                <span className="text-sm text-muted-foreground">{f.label}</span>
                <span className="text-sm font-medium text-foreground">{f.value}</span>
              </div>
            ))}
          </CardContent>
        </Card>

        <div className="mt-6 space-y-3 animate-fade-in" style={{ animationDelay: "200ms" }}>
          <Button variant="outline" className="w-full gap-2" onClick={restartTutorial}>
            <RefreshCw className="h-4 w-4" /> Repetir Tutorial
          </Button>
          <Button variant="destructive" className="w-full gap-2" onClick={handleLogout}>
            <LogOut className="h-4 w-4" /> Cerrar Sesión
          </Button>
        </div>
      </main>
    </div>
  );
}
