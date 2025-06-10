#include "helper.hpp"
#include "data.hpp"
#include "train.cuh"
#include "fhe.hpp"

#include <string>
#include <vector>
#include <iostream>

int main(const int argc, char **argv) {

    if (argc < 4 || argc > 7) {
        std::cerr << "Usage: " << argv[0] << " [perf/train/inference] [naive/cpu/gpu] [random/mnist] [iterations] [accelerated/normal] [boot1/boot2]" << std::endl;
        return EXIT_FAILURE;
    }

    /// --------- Parse all program args. ---------

    exec_t run_mode = TRAIN;
    size_t iterations = 0;
    bool accelerated = false;

    if (std::string(argv[1]) == "perf") {
        if (argc != 5) {
            std::cerr << "Usage: " << argv[0] << "perf [naive/cpu/gpu] [random/mnist] [iterations]" << std::endl;
            return EXIT_FAILURE;
        }
        run_mode = PERFORMANCE;
        iterations = std::stoul(std::string(argv[4]));
        if (iterations == 0) {
            std::cerr << "Error: iterations must be greater than 0." << std::endl;
            return EXIT_FAILURE;
        }
    }
    else if (std::string(argv[1]) == "train") {
        if (argc != 7) {
            std::cerr << "Usage: " << argv[0] << "train [naive/cpu/gpu] [random/mnist] [iterations] [accelerated/normal] [boot1/boot2]" << std::endl;
            return EXIT_FAILURE;
        }
        run_mode = TRAIN;
        iterations = std::stoul(std::string(argv[4]));
        accelerated = is_acceler_from(argv[5]);

        std::string boot = std::string(argv[6]);
        if (boot == "boot1") {
            bootstrap_every_two = false;
        }
        else if (boot == "boot2") {
            bootstrap_every_two = true;
        }
        else {
            std::cerr << "Error: bad value for bootstrapping every 1/2 iterations." << std::endl;
            return EXIT_FAILURE;
        }

        if (iterations == 0) {
            std::cerr << "Error: iterations must be greater than 0." << std::endl;
            return EXIT_FAILURE;
        }
    }
    else if (std::string(argv[1]) == "inference") {
        if (argc != 4) {
            std::cerr << "Usage: " << argv[0] << "inference [naive/cpu/gpu] [random/mnist]" << std::endl;
            return EXIT_FAILURE;
        }
        run_mode = VALIDATION;
    }
    else return EXIT_FAILURE;

    const dataset_t dataset = dataset_from(argv[3]);
    const backend_t backend = backend_from(argv[2]);

    /// --------- Run the program. ---------

    const auto data_name = dataset_name(dataset);
    const auto weight_file = weights_path(backend, dataset);

    if (run_mode == VALIDATION) {
        std::vector<std::vector<double> > data;
        std::vector<double> results;
        const size_t num_features = prepare_data_csv(dataset, run_mode, data, results);

        std::vector<double> weights;
        load_weights(weight_file, num_features, weights);

        switch (backend) {
            case NAIVE:
                naive_inference(data, results, weights);
                break;
            case CPU:
                cpu_inference(data, results, weights);
                break;
            case GPU:
                gpu_inference(data, results, weights);
                break;
            default:
                exit(EXIT_FAILURE);
        }

    }
    else if (run_mode == TRAIN) {
        std::vector<std::vector<double> > data;
        std::vector<double> results;
        const size_t num_features = prepare_data_csv(dataset, run_mode, data, results);

        std::vector<double> weights;
        generate_weights(num_features, weights);

        switch (backend) {
            case NAIVE:
                naive_training(data, results, weights, iterations, accelerated);
                break;
            case CPU:
                cpu_training(data, results, weights, iterations, accelerated);
                break;
            case GPU:
                gpu_training(data, results, weights, iterations, accelerated);
                break;
            default:
                exit(EXIT_FAILURE);
        }

        save_weights(weight_file, weights);
    }
    else if (run_mode == PERFORMANCE) {

        std::vector<std::vector<double> > data_train;
        std::vector<double> results_train;
        std::vector<std::vector<double> > data_val;
        std::vector<double> results_val;
        const size_t num_features_train = prepare_data_csv(dataset, TRAIN, data_train, results_train);
        const size_t num_features_val = prepare_data_csv(dataset, VALIDATION, data_val, results_val);

        if (num_features_train != num_features_val) {
            std::cerr << "Error: num_features_train != num_features_val" << std::endl;
            return EXIT_FAILURE;
        }

        bootstrap_every_two = false;
        auto time_file_train = times_path(dataset, TRAIN, backend);
        auto time_file_val = times_path(dataset, VALIDATION, backend);
        
        for (size_t i = 0; i < iterations; ++i) {

            std::vector<iteration_time_t> times_train;
            std::vector<iteration_time_t> times_val;
            double accuracy = 0.0;

            std::vector<double> weights;
            generate_weights(num_features_train, weights);

            switch (backend) {
                case NAIVE:
                    times_train = naive_training(data_train, results_train, weights, i, false);
                break;
                case CPU:
                    times_train = cpu_training(data_train, results_train, weights, i, false);
                break;
                case GPU:
                    times_train = gpu_training(data_train, results_train, weights, i, false);
                break;
                default:
                    exit(EXIT_FAILURE);
            }

            print_times(time_file_train, times_train, i, false, activation_function, 0.0, TRAIN);

            switch (backend) {
                case NAIVE: {
                    const auto res = naive_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case CPU: {
                    const auto res = cpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case GPU: {
                    auto res = gpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                default:
                    exit(EXIT_FAILURE);
            }

            print_times(time_file_val, times_val, i, false, activation_function, accuracy, VALIDATION);
        }

        for (size_t i = 0; i < iterations; ++i) {

            std::vector<iteration_time_t> times_train;
            std::vector<iteration_time_t> times_val;
            double accuracy = 0.0;

            std::vector<double> weights;
            generate_weights(num_features_train, weights);
            
            switch (backend) {
                case NAIVE:
                    times_train = naive_training(data_train, results_train, weights, i, true);
                break;
                case CPU:
                    times_train = cpu_training(data_train, results_train, weights, i, true);
                break;
                case GPU:
                    times_train = gpu_training(data_train, results_train, weights, i, true);
                break;
                default:
                    exit(EXIT_FAILURE);
            }

            print_times(time_file_train, times_train, i, true, activation_function, 0.0, TRAIN);
            
            switch (backend) {
                case NAIVE: {
                    const auto res = naive_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case CPU: {
                    const auto res = cpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case GPU: {
                    auto res = gpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                default:
                    exit(EXIT_FAILURE);
            }
            
            print_times(time_file_val, times_val, i, true, activation_function, accuracy, VALIDATION);
        }
        
        bootstrap_every_two = true;
        time_file_train = times_path(dataset, TRAIN, backend);
        time_file_val = times_path(dataset, VALIDATION, backend);
        
        for (size_t i = 0; i < iterations; ++i) {

            std::vector<iteration_time_t> times_train;
            std::vector<iteration_time_t> times_val;
            double accuracy = 0.0;

            std::vector<double> weights;
            generate_weights(num_features_train, weights);

            switch (backend) {
                case NAIVE:
                    times_train = naive_training(data_train, results_train, weights, i, false);
                break;
                case CPU:
                    times_train = cpu_training(data_train, results_train, weights, i, false);
                break;
                case GPU:
                    times_train = gpu_training(data_train, results_train, weights, i, false);
                break;
                default:
                    exit(EXIT_FAILURE);
            }

            print_times(time_file_train, times_train, i, false, activation_function, 0.0, TRAIN);

            switch (backend) {
                case NAIVE: {
                    const auto res = naive_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case CPU: {
                    const auto res = cpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case GPU: {
                    auto res = gpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                default:
                    exit(EXIT_FAILURE);
            }

            print_times(time_file_val, times_val, i, false, activation_function, accuracy, VALIDATION);
        }
        
        for (size_t i = 0; i < iterations; ++i) {
  
            std::vector<iteration_time_t> times_train;
            std::vector<iteration_time_t> times_val;
            double accuracy = 0.0;

            std::vector<double> weights;
            generate_weights(num_features_train, weights);

            switch (backend) {
                case NAIVE:
                    times_train = naive_training(data_train, results_train, weights, i, true);
                break;
                case CPU:
                    times_train = cpu_training(data_train, results_train, weights, i, true);
                break;
                case GPU:
                    times_train = gpu_training(data_train, results_train, weights, i, true);
                break;
                default:
                    exit(EXIT_FAILURE);
            }

            print_times(time_file_train, times_train, i, true, activation_function, 0.0, TRAIN);

            switch (backend) {
                case NAIVE: {
                    const auto res = naive_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case CPU: {
                    const auto res = cpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                case GPU: {
                    auto res = gpu_inference(data_val, results_val, weights);
                    times_val = res.first;
                    accuracy = res.second;
                    break;
                }
                default:
                    exit(EXIT_FAILURE);
            }

            print_times(time_file_val, times_val, i, true, activation_function, accuracy, VALIDATION);
        }
        
    }
    else return EXIT_FAILURE;

    return EXIT_SUCCESS;
}