export const priceFmt = new Intl.NumberFormat("fr-SN", {
  style: "currency",
  currency: "XOF",
  maximumFractionDigits: 0,
});

export function formatFcfa(value: number) {
  return priceFmt.format(value);
}