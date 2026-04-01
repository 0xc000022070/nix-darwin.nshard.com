import React, { useState, useEffect, useMemo } from "react";

interface Option {
  [key: string]: unknown;
  type?: string;
  default?: string;
  description?: string;
  example?: string;
  doc?: string;
}

interface OptionsData {
  [key: string]: Option;
}

const OptionsSearch: React.FC = () => {
  const [options, setOptions] = useState<OptionsData>({});
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Load options data
  useEffect(() => {
    const loadOptions = async () => {
      try {
        const response = await fetch("/data/options.json");
        if (!response.ok) {
          throw new Error("Failed to load options");
        }
        const data = await response.json();
        setOptions(data);
        setLoading(false);
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Failed to load options"
        );
        setLoading(false);
      }
    };

    loadOptions();
  }, []);

  // Filter options based on search term
  const filteredOptions = useMemo(() => {
    if (!searchTerm.trim()) {
      return Object.entries(options);
    }

    const lowerSearch = searchTerm.toLowerCase();

    const keyMatches: Array<[string, Option]> = [];
    const descriptionMatches: Array<[string, Option]> = [];

    Object.entries(options).forEach(([key, value]) => {
      // Prioritize key matches
      if (key.toLowerCase().includes(lowerSearch)) {
        keyMatches.push([key, value]);
      } else if (
        value.description &&
        String(value.description).toLowerCase().includes(lowerSearch)
      ) {
        descriptionMatches.push([key, value]);
      } else if (
        value.example &&
        String(value.example).toLowerCase().includes(lowerSearch)
      ) {
        descriptionMatches.push([key, value]);
      }
    });

    // Return key matches first, then description matches
    return [...keyMatches, ...descriptionMatches];
  }, [searchTerm, options]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <div className="mb-4 inline-block h-8 w-8 animate-spin rounded-full border-4 border-gray-300 border-t-black"></div>
          <p className="text-gray-600">Loading options...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-lg border border-red-300 bg-red-50 p-4 text-red-800">
        <p className="font-semibold">Error loading options</p>
        <p className="text-sm">{error}</p>
      </div>
    );
  }

  return (
    <div className="w-full max-w-4xl">
      {/* Search Input */}
      <div className="mb-8">
        <input
          type="text"
          placeholder="Search options by name, description, or examples..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full rounded-lg border border-gray-300 px-4 py-3 text-base shadow-sm focus:border-black focus:outline-none focus:ring-2 focus:ring-black focus:ring-opacity-20"
          autoFocus
        />
        <p className="mt-2 text-sm text-gray-500">
          Found {filteredOptions.length} option{filteredOptions.length !== 1 ? "s" : ""}
        </p>
      </div>

      {/* Results */}
      <div className="space-y-6">
        {filteredOptions.length === 0 ? (
          <div className="rounded-lg border border-gray-200 bg-gray-50 p-8 text-center">
            <p className="text-gray-600">No options found matching your search.</p>
            <p className="mt-2 text-sm text-gray-500">
              Try searching for different keywords or browse all options.
            </p>
          </div>
        ) : (
          filteredOptions.map(([key, value]) => (
            <div
              key={key}
              className="rounded-lg border border-gray-200 bg-white p-6 transition-shadow hover:shadow-md"
            >
              {/* Option Name/Path */}
              <h3 className="font-mono text-lg font-semibold text-black">
                {key}
              </h3>

              {/* Option Details */}
              <div className="mt-3 space-y-2 text-sm text-gray-700">
                {value.type && (
                  <div>
                    <span className="font-semibold text-gray-900">Type:</span>
                    <span className="ml-2 inline-block rounded bg-gray-100 px-2 py-1 font-mono text-xs">
                      {String(value.type)}
                    </span>
                  </div>
                )}

                {value.default && (
                  <div>
                    <span className="font-semibold text-gray-900">
                      Default:
                    </span>
                    <span className="ml-2 font-mono text-xs text-gray-600">
                      {String(value.default)}
                    </span>
                  </div>
                )}
              </div>

              {/* Description */}
              {value.description && (
                <div className="mt-4 text-sm leading-relaxed text-gray-700">
                  {String(value.description)
                    .split("\n")
                    .filter((line) => line.trim())
                    .slice(0, 3)
                    .map((line, idx) => (
                      <p key={idx}>{line}</p>
                    ))}
                </div>
              )}

              {/* Example */}
              {value.example && (
                <div className="mt-4">
                  <p className="text-xs font-semibold text-gray-900">Example:</p>
                  <pre className="mt-2 overflow-x-auto rounded bg-gray-100 p-3 font-mono text-xs text-gray-800">
                    {String(value.example)}
                  </pre>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default OptionsSearch;
