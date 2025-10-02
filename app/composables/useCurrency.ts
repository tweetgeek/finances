export const useCurrency = () => {
  const supabase = useSupabaseClient();

  /**
   * Pobiera kurs waluty z NBP dla danej daty
   */
  const getExchangeRate = async (
    currencyCode: string,
    date: string
  ): Promise<number> => {
    if (currencyCode === 'PLN') return 1;

    try {
      // Format daty: YYYY-MM-DD
      const url = `https://api.nbp.pl/api/exchangerates/rates/a/${currencyCode.toLowerCase()}/${date}/?format=json`;

      const response = await fetch(url);

      if (!response.ok) {
        // Jeśli nie ma kursu dla tej daty (weekend/święto), spróbuj poprzedni dzień
        const prevDate = new Date(date);
        prevDate.setDate(prevDate.getDate() - 1);
        const prevDateStr = prevDate.toISOString().split('T')[0];

        return getExchangeRate(currencyCode, prevDateStr);
      }

      const data = await response.json();
      return data.rates[0].mid;
    } catch (error) {
      console.error('Error fetching exchange rate:', error);
      throw new Error(`Nie udało się pobrać kursu dla ${currencyCode}`);
    }
  };

  /**
   * Przelicza kwotę z jednej waluty na PLN
   */
  const convertToPLN = async (
    amount: number,
    currencyCode: string,
    date: string
  ): Promise<{ amountPLN: number; exchangeRate: number }> => {
    if (currencyCode === 'PLN') {
      return { amountPLN: amount, exchangeRate: 1 };
    }

    const exchangeRate = await getExchangeRate(currencyCode, date);
    const amountPLN = amount * exchangeRate;

    return {
      amountPLN: Math.round(amountPLN * 100) / 100,
      exchangeRate: Math.round(exchangeRate * 10000) / 10000,
    };
  };

  /**
   * Formatuje kwotę z walutą
   */
  const formatCurrency = (amount: number | null, currencyCode: string = 'PLN'): string => {
    if (amount === null) return '-';

    const currencies: Record<string, string> = {
      PLN: 'zł',
      EUR: '€',
      USD: '$',
      GBP: '£',
      CHF: 'CHF',
    };

    const symbol = currencies[currencyCode] || currencyCode;
    const formatted = new Intl.NumberFormat('pl-PL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);

    return `${formatted} ${symbol}`;
  };

  /**
   * Lista dostępnych walut
   */
  const availableCurrencies = [
    { label: 'PLN (złoty)', value: 'PLN', symbol: 'zł' },
    { label: 'EUR (euro)', value: 'EUR', symbol: '€' },
    { label: 'USD (dolar)', value: 'USD', symbol: '$' },
    { label: 'GBP (funt)', value: 'GBP', symbol: '£' },
    { label: 'CHF (frank)', value: 'CHF', symbol: 'CHF' },
  ];

  return {
    getExchangeRate,
    convertToPLN,
    formatCurrency,
    availableCurrencies,
  };
};
