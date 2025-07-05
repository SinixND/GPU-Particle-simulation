#ifndef IG20240317021429
#define IG20240317021429

#include <random>

namespace snx
{
    class RNG
    {
        static inline std::random_device rd_{};

        //* Get 8 integers of random numbers from std::random_device for our seed
        static inline std::seed_seq ss_{
            rd_(),
            rd_(),
            rd_(),
            rd_(),
            rd_(),
            rd_(),
            rd_(),
            rd_()
        };

        static inline std::mt19937 rng_{ ss_ };

    public:
        static inline void seed( int seed )
        {
            rng_.seed( seed );
        }

        //* Returns 0 or 1 with no arguments provided
        static inline int random(
            int min = 0,
            int max = 1
        )
        {
            std::uniform_int_distribution<int> distribution{ min, max };

            return distribution( rng_ );
        }
    };
}
#endif
