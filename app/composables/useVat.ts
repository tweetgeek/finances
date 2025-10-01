export const useVat = () => {
  const round2 = (n: number) => Math.round(n * 100) / 100

  const fromNet = (net: number, rate: number) => {
    const netRounded = round2(net)
    const gross = round2(netRounded * (1 + rate / 100))
    return {
      net: netRounded,
      gross,
      vat: round2(gross - netRounded)
    }
  }

  const fromGross = (gross: number, rate: number) => {
    const grossRounded = round2(gross)
    const net = round2(grossRounded / (1 + rate / 100))
    return {
      net,
      gross: grossRounded,
      vat: round2(grossRounded - net)
    }
  }

  return { fromNet, fromGross, round2 }
}
