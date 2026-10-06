import DashboardShell from "@/components/DashboardShell";

export default function DashLayout({ children }: { children: React.ReactNode }) {
  return <DashboardShell>{children}</DashboardShell>;
}